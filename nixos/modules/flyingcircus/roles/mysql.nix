{ config, lib, pkgs, ... }:

# TODO:
# - maintenance / consistency check
# - listening on SRV interface

with builtins;
with lib;

let
  cfg = config.flyingcircus.roles.mysql;
  fclib = import ../lib;

  current_memory = fclib.current_memory config 256;
  cores = fclib.current_cores config 1;

  root_password_file = "/etc/local/mysql/mysql.passwd";
  root_password_setter =
    if cfg.rootPassword == null
    then "$(${pkgs.apg}/bin/apg -a 1 -M lnc -n 1 -m 12)"
    else "\"${cfg.rootPassword}\"";

  rootPassword =
    if builtins.pathExists root_password_file
    then removeSuffix "\n" (builtins.readFile root_password_file)
    else "";

  isCnf = path: t: path == root_password_file || (hasSuffix ".cnf" path);

  localConfig =
    if pathExists /etc/local/mysql
    then "!includedir ${filterSource isCnf /etc/local/mysql}"
    else "";

  package =
    if config.flyingcircus.roles.mysql55.enable
    then pkgs.mysql55
    else if config.flyingcircus.roles.mysql56.enable
    then pkgs.percona56
    else if config.flyingcircus.roles.mysql57.enable
    then pkgs.percona57
    else null;

  enabled = package != null;

in

{
  options = {

    flyingcircus.roles.mysql = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Safe guard to make sure a specific mysql role is enabled.

          This options must be false.
        '';
      };

      rootPassword = mkOption {
        type = types.nullOr types.string;
        default = null;
        description = ''
          The root password for mysql. If null, a random root
          password will be set.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description =
        ''
          Extra MySQL configuration to append at the end of the
          configuration file. Do not assume this to be located
          in any specific section.
        '';
      };

    };

    flyingcircus.roles.mysql55 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus MySQL 5.5 server role.";
      };
    };

    flyingcircus.roles.mysql56 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus MySQL 5.6 server role.";
      };
    };

    flyingcircus.roles.mysql57 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus MySQL 5.7 server role.";
      };
    };


  };

  config = mkMerge [

  (mkIf (assert !cfg.enable; enabled) {

    services.percona = {
      enable = true;
      package = package;
      rootPassword = root_password_file;
      dataDir = "/srv/mysql";
      extraOptions = ''
        [mysqld]
        default-storage-engine  = innodb
        skip-external-locking
        skip-name-resolve
        max_allowed_packet         = 512M
        bulk_insert_buffer_size    = 128M
        tmp_table_size             = 512M
        max_heap_table_size        = 512M
        lower-case-table-names     = 0
        max_connect_errors         = 20
        default_storage_engine     = InnoDB
        table_definition_cache     = 512
        open_files_limit           = 65535
        sysdate-is-now             = 1
        sql_mode                   = NO_ENGINE_SUBSTITUTION

        init-connect               = 'SET NAMES utf8 COLLATE utf8_unicode_ci'
        character-set-server       = utf8
        collation-server           = utf8_unicode_ci
        character_set_server       = utf8
        collation_server           = utf8_unicode_ci

        # Timeouteinstellung
        interactive_timeout        = 28800
        wait_timeout               = 28800
        connect_timeout            = 10

        bind-address               = 0.0.0.0
        max_connections            = 1000
        thread_cache_size          = 128
        myisam-recover-options     = FORCE
        key_buffer_size            = 64M
        table_open_cache           = 1000
        # myisam-recover           = FORCE
        thread_cache_size          = 8

        query_cache_type           = 1
        query_cache_min_res_unit   = 2k
        query_cache_size           = 80M

        # * InnoDB
        innodb_buffer_pool_size         = ${toString (current_memory * 70 / 100)}M
        innodb_log_buffer_size          = 64M
        innodb_file_per_table           = 1
        innodb_read_io_threads          = ${toString (cores * 4)}
        innodb_write_io_threads         = ${toString (cores * 4)}
        # Percentage. Probably needs local tuning depending on the workload.
        ${lib.optionalString
          (lib.versionAtLeast package.mysqlVersion "5.6")
          "innodb_change_buffer_max_size   = 50"}
        innodb_doublewrite              = 1
        innodb_log_file_size            = 512M
        innodb_log_files_in_group       = 4
        innodb_flush_method             = O_DSYNC
        innodb_open_files               = 800
        innodb_stats_on_metadata        = 0
        innodb_lock_wait_timeout        = 120

        [mysqldump]
        quick
        quote-names
        max_allowed_packet    = 512M

        [xtrabackup]
        target_dir                      = /opt/backup/xtrabackup
        compress-threads                = ${toString (cores * 2)}
        compress
        parallel            = 3

        [isamchk]
        key_buffer        = 16M

        # flyingcircus.roles.mysql.extraConfig
        ${cfg.extraConfig}

        # /etc/local/mysql/*
        ${localConfig}
      '';
    };

    system.activationScripts.fcio-mysql-init =
    let
      mysql = config.services.percona.package;
    in
      stringAfter
        [ "users" "groups" ]
        ''
          # Configure initial root password for mysql.
          # * set password
          # * write password to /etc/mysql/mysql.passwd
          # * write /root/.my.cnf
          install -d -o mysql -g service  -m 02775 /etc/local/mysql/

          umask 0066
          if [[ ! -f ${root_password_file} ]]; then
            pw=${root_password_setter}
            echo -n "''${pw}" > ${root_password_file}
          fi
          chown root:service ${root_password_file}
          chmod 640 ${root_password_file}

          if [[ ! -f /root/.my.cnf ]]; then
            touch /root/.my.cnf
            chmod 640 /root/.my.cnf
            pw=$(<${root_password_file})
            cat > /root/.my.cnf <<__EOT__
          # The following options will be passed to all MySQL clients
          [client]
          password = ''${pw}
          __EOT__
          fi
        '';

    environment.etc."local/mysql/README.txt".text = ''
      MySQL (${package.name}) is running on this machine.

      You can find the password for the mysql root user in the file `mysql.passwd`.
      Service users can read the password file.

      To connect as root, run:

      $ mysql -h localhost -uroot -p$(< /etc/local/mysql/mysql.passwd)

      This directory (/etc/local/mysql) is included in the mysql configuration.
      To set custom options, add a `local.cnf` (or any other *.cnf) file here, and
      run `sudo fc-manage --build`.

      ATTENTION: Changes in this directory will restart MySQL to activate the
      new configuration.

      For more information, see our documentation at
      https://flyingcircus.io/doc/guide/platform_nixos/mysql.html.
    '';

    systemd.services.mysql-maintenance = {
      description = "Timed MySQL maintenance tasks";
      after = [ "mysql.service" ];
      wants = [ "mysql-maintenance.timer" ];
      partOf = [ "mysql.service" ];

      path = with pkgs; [ config.services.percona.package ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${./mysql-maintenance.sh}";
      };
    };

    systemd.timers.mysql-maintenance = {
      description = "Timer for MySQL maintenance";
      partOf = [ "mysql.service" "mysql-maintenance.service" ];

      timerConfig = {
        onCalendar = "weekly";    # XXX Randomize!
      };
    };

    security.sudo.extraConfig = ''
      # MySQL sudo rules

      Cmnd_Alias      MYSQL_RESTART = /run/current-system/sw/bin/systemctl restart mysql
      Cmnd_Alias      CHECK_MYSQL = ${pkgs.sensu}/bin/check-mysql-alive.rb
      %service        ALL=(root) MYSQL_RESTART
      %sudo-srv       ALL=(root) MYSQL_RESTART
      %sensuclient    ALL=(mysql) ALL
      %sensuclient    ALL=(root) CHECK_MYSQL
    '';

    services.udev.extraRules = ''
      # increase readahead for mysql
      SUBSYSTEM=="block", ATTR{queue/rotational}=="1", ACTION=="add|change", KERNEL=="vd[a-z]", ATTR{bdi/read_ahead_kb}="1024", ATTR{queue/read_ahead_kb}="1024"
    '';

    environment.systemPackages = [
        pkgs.innotop
        pkgs.qpress
        pkgs.xtrabackup
    ];

    flyingcircus.services.sensu-client.checks = {
      mysql = {
        notification = "MySQL alive";
        # sensu needs to be in the service class for accessing the root_password_file
        command = ''
          /var/setuid-wrappers/sudo -u root \
          ${pkgs.sensu}/bin/check-mysql-alive.rb -d mysql -i /root/.my.cnf
        '';
      };
    };

    services.telegraf.inputs = {
      mysql = [{
        servers = ["root:${rootPassword}@unix(/run/mysqld/mysqld.sock)/?tls=false"];
      }];
    };
  })

  {
    flyingcircus.roles.statshost.prometheusMetricRelabel = [
      {
        source_labels = [ "__name__" "command" ];
        # Only if there is no command set.
        regex = "(mysql_commands)_(.+);$";
        replacement = "\${2}";
        target_label = "command";
      }
      {
        source_labels = [ "__name__" ];
        regex = "(mysql_commands)_(.+)";
        replacement = "\${1}_total";
        target_label = "__name__";
      }
      {
        source_labels = [ "__name__" ];
        regex = "(mysql_handler)_(.+)";
        replacement = "\${2}";
        target_label = "handler";
      }
      {
        source_labels = [ "__name__" ];
        regex = "(mysql_handler)_(.+)";
        replacement = "mysql_handlers_total";
        target_label = "__name__";
      }
      {
        source_labels = [ "__name__" ];
        regex = "(mysql_innodb_rows)_(.+)";
        replacement = "\${2}";
        target_label = "operation";
      }
      {
        source_labels = [ "__name__" ];
        regex = "(mysql_innodb_rows)_(.+)";
        replacement = "mysql_innodb_row_ops_total";
        target_label = "__name__";
      }
      {
        source_labels = [ "__name__" ];
        regex = "(mysql_innodb_buffer_pool_pages)_(.+)";
        replacement = "\${2}";
        target_label = "state";
      }
      {
        source_labels = [ "__name__" ];
        regex = "(mysql_innodb_buffer_pool_pages)_(.+)";
        replacement = "mysql_buffer_pool_pages";
        target_label = "__name__";
      }
    ];
    flyingcircus.roles.statshost.globalAllowedMetrics = [ "mysql" ];
  }
  ];
}
