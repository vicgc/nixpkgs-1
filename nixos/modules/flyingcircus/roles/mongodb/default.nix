{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.flyingcircus;
  mcfg = config.services.mongodb;
  fclib = import ../../lib;

  listen_addresses =
    fclib.listenAddresses config "lo" ++
    fclib.listenAddresses config "ethsrv";

  local_config_path = /etc/local/mongodb/mongodb.yaml;

  local_config =
    if pathExists local_config_path
    then builtins.readFile local_config_path
    else "";

  # Use a completely own version of mongodb.conf (not resorting to NixOS
  # defaults). The stock version includes a hard-coded "syslog = true"
  # statement.
  mongoCnf = pkgs.writeText "mongodb.yaml" ''
    net.bindIp: "${mcfg.bind_ip}"
    net.ipv6: true

    ${optionalString mcfg.quiet "systemLog.quiet: true"}
    systemLog.path: /var/log/mongodb/mongodb.log
    systemLog.destination: file
    systemLog.logAppend: true
    systemLog.logRotate: reopen

    storage.dbPath: ${mcfg.dbpath}

    processManagement.fork: true
    processManagement.pidFilePath: ${mcfg.pidFile}

    ${optionalString (mcfg.replSetName != "") "replication.replSetName: ${mcfg.replSetName}"}

    ${mcfg.extraConfig}
    ${local_config}
  '';

  mongo_check = pkgs.callPackage ./check.nix { };

  package =
    if cfg.roles.mongodb32.enable
    then pkgs.mongodb_3_2
    else if cfg.roles.mongodb30.enable
    then pkgs.mongodb_3_0
    else null;

  enable = package != null;

in
{
  options = {

    flyingcircus.roles.mongodb30 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable MongoDB 3.0.";
      };
    };

    flyingcircus.roles.mongodb32 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable MongoDB 3.2.";
      };
    };

  };

  config = mkIf enable {

    environment.systemPackages = [
      pkgs.mongodb-tools
    ];

    services.mongodb.enable = true;
    services.mongodb.dbpath = "/srv/mongodb";
    services.mongodb.bind_ip = concatStringsSep "," listen_addresses;
    services.mongodb.pidFile = "/run/mongodb.pid";
    services.mongodb.package = package;

    systemd.services.mongodb = {
      preStart = "echo never > /sys/kernel/mm/transparent_hugepage/defrag";
      postStop = "echo always > /sys/kernel/mm/transparent_hugepage/defrag";
      # intial creating of journal takes ages:
      serviceConfig.TimeoutStartSec = fclib.mkPlatform 1200;
      serviceConfig.LimitNOFILE = 64000;
      serviceConfig.LimitNPROC = 32000;
      serviceConfig.ExecStart = mkForce ''
        ${mcfg.package}/bin/mongod --config ${mongoCnf}
      '';
      reload = ''
        if [[ -f ${mcfg.pidFile} ]]; then
          kill -USR1 $(< ${mcfg.pidFile} )
        fi
      '';
    };

    users.users.mongodb = {
      shell = "/run/current-system/sw/bin/bash";
      home = "/srv/mongodb";
    };

    system.activationScripts.flyingcircus-mongodb =
    let
      uid = toString config.ids.uids.mongodb;
    in ''
      install -d -o ${uid} /{srv,var/log}/mongodb
      install -d -o ${uid} -g service -m 02775 /etc/local/mongodb
    '';

    security.sudo.extraConfig = ''
      # Service users may switch to the mongodb system user
      %sudo-srv ALL=(mongodb) ALL
      %service ALL=(mongodb) ALL
      %sensuclient ALL=(mongodb) ALL
    '';

    environment.etc."local/mongodb/README.txt".text = ''
      Put your local mongodb configuration into `mongodb.yaml` here.
      It will be joined with the basic config.
    '';

    services.logrotate.config = ''
      /var/log/mongodb/*.log {
        nocreate
        postrotate
          systemctl reload mongodb
        endscript
      }
    '';

    flyingcircus.services.sensu-client.checks = {
      mongodb = {
        notification = "MongoDB alive";
        command = ''
          /var/setuid-wrappers/sudo -u mongodb -- \
            ${mongo_check}/bin/check_mongo -d mongodb
        '';
      };
    };

    flyingcircus.services.sensu-client.expectedConnections = {
      warning = 60000;
      critical = 63000;
    };

    services.telegraf.inputs = {
      mongodb = [{
        servers = ["mongodb://127.0.0.1:27017"];
        gather_perdb_stats = true;
      }];
    };

  };
}
