{ config, lib, pkgs, ... }:

# Our management agent keeping the system up to date, configuring it based on
# changes to our nixpkgs clone and data from our directory

with lib;

let
  cfg = config.flyingcircus;

  # migration for #26699
  deprecatedBuildWithMaintenanceFlag =
    builtins.pathExists "/etc/local/build-with-maintenance";

  channelAction =
    if deprecatedBuildWithMaintenanceFlag || cfg.agent.with-maintenance
    then "--channel-with-maintenance"
    else "--channel";

  humanGid = toString config.ids.gids.users;
  serviceGid = toString config.ids.gids.service;

in {
  options = {
    flyingcircus.agent = {
      enable = mkOption {
        default = true;  # <-!!!
        description = "Run the Flying Circus management agent automatically.";
        type = types.bool;
      };

      with-maintenance = mkOption {
        default = false;
        description = "Perform NixOS updates in scheduled maintenance.";
        type = types.bool;
      };

      steps = mkOption {
        type = types.str;
        default = "--directory --system-state --maintenance ${channelAction}";
        description = "Steps to run by the agent.";
      };

      collect-garbage = mkEnableOption
        "automatic scanning for Nix store references and garbage collection";
    };
  };

  config = mkMerge [
    {
      # migration for #26699
      warnings = lib.optional deprecatedBuildWithMaintenanceFlag ''
        Deprecated "build-with-maintenance" flag file detected.
        Set NixOS option "flyingcircus.agent.with-maintenance" instead and
        delete the old flag file to get rid of this warning.
      '';

      # We always install the management agent, but we don't necessarily
      # enable it running automatically.
      environment.systemPackages = [
        pkgs.fcmanage
      ];

      systemd.services.fc-manage = rec {
        description = "Flying Circus Management Task";
        restartIfChanged = false;
        wants = [ "network.target" ];
        after = wants;
        serviceConfig.Type = "oneshot";
        path = [ config.system.build.nixos-rebuild ];

        # This configuration is stolen from NixOS' own automatic updater.
        environment = config.nix.envVars // {
          inherit (config.environment.sessionVariables) NIX_PATH SSL_CERT_FILE;
          HOME = "/root";
          PATH = "/run/current-system/sw/sbin:/run/current-system/sw/bin";
          LANG = "en_US.utf8";
        };
        script = ''
          failed=0
          ${pkgs.fcmanage}/bin/fc-manage -E ${cfg.enc_path} ${cfg.agent.steps} || failed=$?
          ${pkgs.fcmanage}/bin/fc-resize -E ${cfg.enc_path} || failed=$?
          exit $failed
        '';
      };

      systemd.tmpfiles.rules = [
        "r! /reboot"
        "d /var/spool/maintenance/archive - - - 90d"
      ];

      security.sudo.extraConfig = ''
        # Allow applying config and restarting services to service users
        Cmnd_Alias  FCMANAGE = ${pkgs.fcmanage}/bin/fc-manage --build
        %sudo-srv ALL=(root) FCMANAGE
        %service  ALL=(root) FCMANAGE
      '';

      systemd.services.fc-collect-garbage =
      let script = ''
        #! ${pkgs.stdenv.shell} -e
        failed=0
        while read user home; do
          sudo -u $user -H -- \
            fc-userscan -v -s 1 -S -c $home/.cache/fc-userscan.json.gz \
            $home || failed=1
        done < <(getent passwd | \
                 awk -F: '$4 == ${humanGid} || $4 == ${serviceGid} \
                   { print $1 " " $6 }')

        if (( failed )); then
          echo "ERROR: fc-userscan failed"
          exit 1
        else
          nice -n19 nix-collect-garbage --delete-older-than 3d
        fi
      '';
      in {
        description = "Scan users for Nix store references and collect garbage";
        serviceConfig.Type = "oneshot";
        path = with pkgs; [ fcuserscan gawk nix glibc sudo ];
        environment = { LANG = "en_US.utf8"; };
        inherit script;
      };
    }

    (mkIf cfg.agent.enable {
      systemd.timers.fc-manage = {
        description = "Timer for fc-manage";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnStartupSec = "10s";
          OnUnitActiveSec = "10m";
          # Not yet supported by our systemd version.
          # RandomSec = "3m";
        };
      };
    })

    (mkIf cfg.agent.collect-garbage {
      systemd.timers.fc-collect-garbage = {
        description = "Timer for fc-collect-garbage";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnStartupSec = "49m";
          OnUnitActiveSec = "1d";
        };
      };
    })
  ];
}
