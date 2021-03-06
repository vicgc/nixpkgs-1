{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.flyingcircus;
  fclib = import ../lib;

  # This looks clunky.
  version =
      if cfg.roles.postgresql93.enable
      then "9.3"
      else if cfg.roles.postgresql94.enable
      then "9.4"
      else if cfg.roles.postgresql95.enable
      then "9.5"
      else if cfg.roles.postgresql96.enable
      then "9.6"
      else null;


  # Is *any* postgres role enabled?
  postgres_enabled = version != null;

  package = {
    "9.3" = pkgs.postgresql93;
    "9.4" = pkgs.postgresql94;
    "9.5" = pkgs.postgresql95;
    "9.6" = pkgs.postgresql96;
  };

  current_memory = fclib.current_memory config 256;

  shared_memory_max = current_memory / 2 * 1048576;

  shared_buffers =
    fclib.min [
      (fclib.max [16 (current_memory / 4)])
       (shared_memory_max * 4 / 5)];

  work_mem =
    fclib.max [1 (shared_buffers / 200)];

  maintenance_work_mem =
    fclib.max [16 work_mem (current_memory / 20)];

  wal_buffers =
    fclib.max [
      (fclib.min [64 (shared_buffers / 32)])
      1];

  random_page_cost =
    let rbd_pool =
      attrByPath [ "parameters" "rbd_pool" ] null config.flyingcircus.enc;
    in
    if rbd_pool == "rbd.ssd" then 1 else 4;

  listen_addresses =
    fclib.listenAddresses config "lo" ++
    fclib.listenAddresses config "ethsrv";

  # using this ugly expression is the only way to get a dynamic path into the
  # Nix store
  local_config_path = /etc/local/postgresql + "/${version}";

  local_config =
    if postgres_enabled && pathExists local_config_path
    then "include_dir '${local_config_path}'"
    else "";

in
{
  options = {

    flyingcircus.roles.postgresql93 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus PostgreSQL 9.3 server role.";
      };
    };

    flyingcircus.roles.postgresql94 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus PostgreSQL 9.4 server role.";
      };
    };

    flyingcircus.roles.postgresql95 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus PostgreSQL 9.5 server role.";
      };
    };
    flyingcircus.roles.postgresql96 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus PostgreSQL 9.6 server role.";
      };
    };

  };

  config = mkMerge [

  (mkIf postgres_enabled (
  let
    postgresqlPkg = builtins.getAttr version package;
  in
  {
    services.postgresql.enable = true;
    services.postgresql.package = postgresqlPkg;
    services.postgresql.extraPlugins = [
      (pkgs.postgis.override { postgresql = postgresqlPkg; })
    ] ++ lib.optionals
      (lib.versionAtLeast version "9.6")
      [ (pkgs.rum.override { postgresql = postgresqlPkg; }) ];

    services.postgresql.initialScript = ./postgresql-init.sql;
    services.postgresql.dataDir = "/srv/postgresql/${version}";
    systemd.services.postgresql.bindsTo = [ "network-addresses-ethsrv.service" ];

    systemd.services.postgresql.postStart =
    let
      psql = "${postgresqlPkg}/bin/psql";
    in ''
      if ! ${psql} -c '\du' template1 | grep -q '^ *nagios *|'; then
        ${psql} -c 'CREATE ROLE nagios NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT LOGIN' template1
      fi
      if ! ${psql} -l | grep -q '^ *nagios *|'; then
        ${postgresqlPkg}/bin/createdb nagios
      fi
      ${psql} -q -d nagios -c 'REVOKE ALL ON SCHEMA public FROM PUBLIC CASCADE;'
    '';

    users.users.postgres = {
      shell = "/run/current-system/sw/bin/bash";
      home = "/srv/postgresql";
    };

    system.activationScripts.flyingcircus_postgresql = ''
      install -d -o ${toString config.ids.uids.postgres} /srv/postgresql
      install -d -o ${toString config.ids.uids.postgres} -g service -m 02775 \
        /etc/local/postgresql/${version}
    '';

    security.sudo.extraConfig = ''
      # Service users may switch to the postgres system user
      %sudo-srv ALL=(postgres) ALL
      %service ALL=(postgres) ALL
      %sensuclient ALL=(postgres) ALL
    '';

    # System tweaks
    boot.kernel.sysctl = {
      "kernel.shmmax" = toString shared_memory_max;
      "kernel.shmall" = toString (shared_memory_max / 4096);
    };

    services.udev.extraRules = ''
      # increase readahead for postgresql
      SUBSYSTEM=="block", ATTR{queue/rotational}=="1", ACTION=="add|change", KERNEL=="vd[a-z]", ATTR{bdi/read_ahead_kb}="1024", ATTR{queue/read_ahead_kb}="1024"
    '';

    # Custom postgresql configuration
    services.postgresql.extraConfig = ''
      #------------------------------------------------------------------------------
      # CONNECTIONS AND AUTHENTICATION
      #------------------------------------------------------------------------------
      listen_addresses = '${concatStringsSep "," listen_addresses}'
      max_connections = 400
      #------------------------------------------------------------------------------
      # RESOURCE USAGE (except WAL)
      #------------------------------------------------------------------------------
      # available memory: ${toString current_memory}MB
      shared_buffers = ${toString shared_buffers}MB   # starting point is 25% RAM
      temp_buffers = 16MB
      work_mem = ${toString work_mem}MB
      maintenance_work_mem = ${toString maintenance_work_mem}MB
      #------------------------------------------------------------------------------
      # QUERY TUNING
      #------------------------------------------------------------------------------
      effective_cache_size = ${toString (shared_buffers * 2)}MB

      random_page_cost = ${toString random_page_cost}
      # version-specific resource settings for >=9.3
      effective_io_concurrency = 100

      #------------------------------------------------------------------------------
      # WRITE AHEAD LOG
      #------------------------------------------------------------------------------
      wal_level = hot_standby
      wal_buffers = ${toString wal_buffers}MB
      ${optionalString (lib.versionOlder version "9.5")
          "checkpoint_segments = 100"
      }
      checkpoint_completion_target = 0.9
      archive_mode = off

      #------------------------------------------------------------------------------
      # ERROR REPORTING AND LOGGING
      #------------------------------------------------------------------------------
      log_min_duration_statement = 1000
      log_checkpoints = on
      log_connections = on
      log_line_prefix = 'user=%u,db=%d '
      log_lock_waits = on
      log_autovacuum_min_duration = 5000
      log_temp_files = 1kB
      shared_preload_libraries = 'auto_explain'
      auto_explain.log_min_duration = '3s'

      #------------------------------------------------------------------------------
      # CLIENT CONNECTION DEFAULTS
      #------------------------------------------------------------------------------
      datestyle = 'iso, mdy'
      lc_messages = 'en_US.utf8'
      lc_monetary = 'en_US.utf8'
      lc_numeric = 'en_US.utf8'
      lc_time = 'en_US.utf8'

      ${local_config}
    '';

    environment.etc."local/postgresql/${version}/README.txt".text = ''
        Put your local postgresql configuration here. This directory
        is being included with include_dir.
        '';

    services.postgresql.authentication = ''
      local postgres root       trust
      # trusted access for Nagios
      host    nagios          nagios          0.0.0.0/0               trust
      host    nagios          nagios          ::/0                    trust
      # authenticated access for others
      host all  all  0.0.0.0/0  md5
      host all  all  ::/0       md5
    '';

    flyingcircus.services.sensu-client.checks = {
      postgresql = {
        notification = "PostgreSQL alive";
        command = "/var/setuid-wrappers/sudo -u postgres check-postgres-alive.rb -d postgres";
        interval = 120;
      };
    } // lib.listToAttrs (
      map (host:
          let sane_host = replaceStrings [":"] ["_"] host;
          in
          { name = "postgresql-listen-${sane_host}-5432";
            value = {
              notification = "PostgreSQL listening on ${host}:5432";
              command = "check-postgres-alive.rb -h ${host} -u nagios -d nagios -P 5432";
              interval = 120;
            };
          })
        listen_addresses);

    services.telegraf.inputs = {
      postgresql = [{
        address = "host=/tmp user=root sslmode=disable dbname=postgres";
      }];
    };

  }))

  {
    flyingcircus.roles.statshost.globalAllowedMetrics = [ "postgresql" ];
  }
  ];
}
