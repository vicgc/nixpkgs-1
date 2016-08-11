{ config, lib, ... }:

with lib;

let
  cfg = config.flyingcircus.roles.loghost-client;

  loghost_server = lib.findFirst
    (host: host.service == "loghost-server")
    null
    config.flyingcircus.enc_services;

  graylog =
    if loghost_server != null then ''
      action(type="omfwd"
          Target="${loghost_server.address}"
          Port="10514"
          Protocol="udp")
    ''
    else
      "";

in

  {
    options =  {
      flyingcircus.roles.loghost-client = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable the flyingcircus loghost-client role";
        };
      };
    };

    config = mkIf (cfg.enable && loghost_server != null) {

      flyingcircus.syslog.extraRules = graylog;
    };
  }

