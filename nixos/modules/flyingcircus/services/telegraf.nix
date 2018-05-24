{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.telegraf;

  telegrafConfig = { inputs = cfg.inputs; } // cfg.extraConfig;
  configFile = pkgs.runCommand "telegraf-config.toml" {
    buildInputs = [ pkgs.remarshal ];
  } ''
    remarshal -if json -of toml \
      < ${pkgs.writeText "config.json" (builtins.toJSON telegrafConfig)} \
      > $out
  '';

  startupOptions = "--config '${configFile}'" +
    optionalString (cfg.configDir != null)
      " --config-directory '${cfg.configDir}'";

in {
  ###### interface
  options = {
    services.telegraf = {
      enable = mkEnableOption "telegraf server";

      package = mkOption {
        default = pkgs.telegraf;
        defaultText = "pkgs.telegraf";
        description = "Which telegraf derivation to use";
        type = types.package;
      };

      configDir = mkOption {
        description = "Additional configuration directory.";
        default = null;
        type = types.nullOr types.path;
      };

      inputs = mkOption {
        default = {};
        type = types.attrsOf (types.listOf types.attrs);
      };

      extraConfig = mkOption {
        default = {};
        description = "Extra configuration options for telegraf";
        type = types.attrsOf types.attrs;
        example = {
          outputs = {
            influxdb = [ { urls = [ "http://localhost:8086" ]; database = "telegraf"; } ];
          };
          inputs = {
            statsd = [ { service_address = ":8125"; delete_timings = true; } ];
          };
        };
      };
    };
  };

  ###### implementation
  config = mkIf config.services.telegraf.enable {
    systemd.services.telegraf = {
      description = "Telegraf Agent";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ pkgs.net_snmp ];
      serviceConfig = {
        ExecStart=''${cfg.package}/bin/telegraf ${startupOptions}'';
        ExecReload="${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        User = "telegraf";
        Restart = "always";
      };
    };

    users.extraUsers = [ {
      name = "telegraf";
      uid = config.ids.uids.telegraf;
      description = "telegraf daemon user";
    } ];
  };
}
