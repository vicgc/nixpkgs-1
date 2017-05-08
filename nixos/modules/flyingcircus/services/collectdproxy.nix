{ config, lib, pkgs, ... }:

with lib;

let
  cfg_loc = config.services.collectdproxy.location;
  cfg_stats = config.services.collectdproxy.statshost;

in {
  options = {

    services.collectdproxy.location = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable proxy in for a location.";
      };

      statshost = mkOption {
        type = types.str;
        description = "name of statshost";
      };

      listen_addr = mkOption {
        type = types.str;
        description = "Bind to";
      };

    };

    services.collectdproxy.statshost = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable.";
      };
      send_to = mkOption {
        type = types.str;
        description = "Where to send the uncompressed data to (host:port)";
      };

    };

  };

  config = mkMerge [
    (mkIf config.services.collectdproxy.location.enable  {
      systemd.services.collectdproxy-location = rec {
        description = "collectd Location proxy";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network.target" ];
        after = wants;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.collectdproxy}/bin/location-proxy \
              -s ${cfg_loc.statshost} \
              -l ${cfg_loc.listen_addr}
          '';
          Restart = "always";
          RestartSec = "60s";
          StandardOutput = "journal";
          StandardError = "journal";
          User = "nobody";
          Type = "simple";
        };
      };
    })

   (mkIf config.services.collectdproxy.statshost.enable  {
      systemd.services.collectdproxy-statshost = rec {
        description = "collectd Statshost proxy";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network.target" ];
        after = wants;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.collectdproxy}/bin/statshost-proxy -s ${cfg_stats.send_to}
          '';
          Restart = "always";
          RestartSec = "60s";
          StandardOutput = "journal";
          StandardError = "journal";
          User = "nobody";
          Type = "simple";
        };
      };
    })
  ];
}
