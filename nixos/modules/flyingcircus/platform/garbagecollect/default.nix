{ config, lib, pkgs, ... }:

# Our management agent keeping the system up to date, configuring it based on
# changes to our nixpkgs clone and data from our directory

with lib;

let
  cfg = config.flyingcircus;

  enableTimer =
    !(attrByPath [ "parameters" "production" ] true cfg.enc) ||
    cfg.agent.collect-garbage;

  collectCmd = optionalString
    cfg.agent.collect-garbage
    "nice -n19 nix-collect-garbage --delete-older-than 3d";

  humanGid = toString config.ids.gids.users;
  serviceGid = toString config.ids.gids.service;
  stamp = "/var/lib/fc-collect-garbage.stamp";

  script = ''
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
      : nix-collect-garbage enabled depending on feature flag
      ${collectCmd}
    fi
    stopped=$(date +%s)
    echo $((stopped - started)) > ${stamp}
  '';

in {
  options = {
    flyingcircus.agent = {
      collect-garbage = mkEnableOption
        "automatic scanning for Nix store references and garbage collection";
    };
  };

  config = mkMerge [
    {
      systemd.services.fc-collect-garbage = {
        description = "Scan users for Nix store references and collect garbage";
        serviceConfig.Type = "oneshot";
        path = with pkgs; [ fcuserscan gawk nix glibc sudo ];
        environment = { LANG = "en_US.utf8"; };
        inherit script;
      };
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
