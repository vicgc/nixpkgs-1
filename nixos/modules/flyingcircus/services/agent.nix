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
        description = "Perform channel updates in scheduled maintenance.";
        type = types.bool;
      };

      steps = mkOption {
        type = types.str;
        default = "${channelAction} --automatic --directory --system-state \\
          --maintenance";
        description = ''
          Steps to run by the agent (besides channel with/without maintenance
          action).
        '';
      };

      interval = mkOption {
        type = types.int;
        default = 120;
        description = "Run channel updates every N minutes.";
      };

    };
  };

  config = mkMerge [
    {
      # migration for #26699
      warnings = optional deprecatedBuildWithMaintenanceFlag ''
        Deprecated "build-with-maintenance" flag file detected.
        Set NixOS option "flyingcircus.agent.with-maintenance" instead and
        delete the old flag file to get rid of this warning.
      '';

      # We always install the management agent, but we don't necessarily
      # enable it running automatically.
      environment.systemPackages = [
        pkgs.fcmanage
      ];

      systemd.tmpfiles.rules = [
        "r! /reboot"
        "r /var/lib/fc-manage/stamp-channel-update"
        "d /var/spool/maintenance/archive - - - 90d"
        "d /var/lib/fc-manage"
      ];

      security.sudo.extraConfig = ''
        # Allow applying config and restarting services to service users
        Cmnd_Alias  FCMANAGE = ${pkgs.fcmanage}/bin/fc-manage --build
        %sudo-srv ALL=(root) FCMANAGE
        %service  ALL=(root) FCMANAGE
      '';
    }

    (mkIf cfg.agent.enable {
      # Do not include the service if the agent is not enabled. This allows
      # deciding, i.e. for Vagrant, that the image should not start the
      # general fc-manage service upon boot, which might fail.
      systemd.services.fc-manage = rec {
        description = "Flying Circus Management Task";
        restartIfChanged = false;
        wants = [ "network.target" ];
        after = wants;
        serviceConfig.Type = "oneshot";
        path = with pkgs; [
          fcmanage
          xfsprogs
          config.system.build.nixos-rebuild
        ];

        # This configuration is stolen from NixOS' own automatic updater.
        environment = config.nix.envVars // {
          inherit (config.environment.sessionVariables) NIX_PATH SSL_CERT_FILE;
          HOME = "/root";
          LANG = "en_US.utf8";
        };
        script = let interval = toString cfg.agent.interval; in
        ''
          failed=0
          mkdir -p /var/lib/fc-manage
          fc-manage -E ${cfg.enc_path} -i ${interval} ${cfg.agent.steps} || failed=$?
          fc-resize -E ${cfg.enc_path} || failed=$?
          exit $failed
        '';
      };

      systemd.timers.fc-manage = {
        description = "Timer for fc-manage";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnStartupSec = "10s";
          OnUnitInactiveSec = "10m";
          # Not yet supported by our systemd version.
          # RandomSec = "3m";
        };
      };
    })
  ];
}
