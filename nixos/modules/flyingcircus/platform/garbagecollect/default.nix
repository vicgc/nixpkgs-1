{ config, lib, pkgs, ... }:

# Our management agent keeping the system up to date, configuring it based on
# changes to our nixpkgs clone and data from our directory

with lib;

let
  cfg = config.flyingcircus;

  isStaging = !(attrByPath [ "parameters" "production" ] true cfg.enc);
  enableTimer = isStaging || cfg.agent.collect-garbage;

  collectCmd = if cfg.agent.collect-garbage
    then "nice -n19 nix-collect-garbage --delete-older-than 3d"
    else "echo 'nix-collect-garbage disabled (feature switch)'";

  humanGid = toString config.ids.gids.users;
  serviceGid = toString config.ids.gids.service;
  stamp = "/var/lib/fc-collect-garbage.stamp";

  script = ''
    sleep $[ $RANDOM % 60 ]
    started=$(date +%s)
    failed=0
    while read user home; do
      sudo -u $user -H -- \
        fc-userscan -v -S -s 2 -c $home/.cache/fc-userscan.cache \
        -z '*.egg' -E ${./userscan.exclude} \
        $home || failed=1
    done < <(getent passwd | awk -F: '$4 == ${humanGid} || $4 == ${serviceGid} \
              { print $1 " " $6 }')

    if (( failed )); then
      echo "ERROR: fc-userscan failed"
      exit 1
    else
      ${collectCmd}
    fi
    stopped=$(date +%s)
    echo $((stopped - started)) > ${stamp}
  '';

in {
  options = {
    flyingcircus.agent = {
      collect-garbage = mkOption {
        default =
          # incremental roll-out
          isStaging && (attrByPath [ "parameters" "id" ] 999999 cfg.enc) < 5000;
        description = ''
          Whether to enable automatic scanning for Nix store references and
          garbage collection.
        '';
        type = types.bool;
      };
    };
  };

  config = mkMerge [
    {
      systemd.services.fc-collect-garbage = {
        description = "Scan users for Nix store references and collect garbage";
        restartIfChanged = false;
        serviceConfig.Type = "oneshot";
        path = with pkgs; [ fcuserscan gawk nix glibc sudo ];
        environment = { LANG = "en_US.utf8"; };
        inherit script;
      };

      environment.etc."nixos/garbagecollect-protect-references".text = ''
        # The following store paths will be needed on every evaluation but are
        # not referenced anywhere else. We mention them here to protect them
        # from garbage collection.
        ${pkgs.pkgs_17_03_src}
        ${pkgs.pkgs_17_09_src}
      '';
    }

    (mkIf enableTimer {

      systemd.timers.fc-collect-garbage = {
        description = "Timer for fc-collect-garbage";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnStartupSec = "49m";
          OnUnitInactiveSec = "1d";
          AccuracySec = "1h";
        };
      };

      flyingcircus.services.sensu-client.checks.fc-collect-gabage = {
        notification = "nix-collect-garbage stamp recent";
        command = ''
          ${pkgs.nagiosPluginsOfficial}/bin/check_file_age -f ${stamp} \
          -w 216000 -c 432000 && echo "| time=$(<${stamp})s;;;0"
        '';
      };

    })
  ];
}
