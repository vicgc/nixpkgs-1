{ config, lib, pkgs, ... }:

let
  cfg = config.flyingcircus;

in
{
  config = {
    fileSystems."/".options = "usrquota,prjquota";

    environment.etc.projects.text = ''
      1:/
    '';

    environment.etc.projid.text = ''
      rootfs:1
    '';

    systemd.additionalUpstreamSystemUnits = [
      "systemd-quotacheck.service"
      "quotaon.service"
    ];

    system.activationScripts.setupXFSQuota = {
      text =
        let
          msg = "Reboot to activate filesystem quotas";
        in
        # keep the grep expression in sync with that one in fcmanage/resize.py
        with pkgs; ''
          if ! egrep -q ' / .*usrquota,.*prjquota' /proc/self/mounts; then
            if ! ${fcmaintenance}/bin/list-maintenance | fgrep -q "${msg}";
            then
              ${fcmaintenance}/bin/scheduled-reboot -c "${msg}"
            fi
          fi
        '';
        deps = [ ];
    };
  };
}
