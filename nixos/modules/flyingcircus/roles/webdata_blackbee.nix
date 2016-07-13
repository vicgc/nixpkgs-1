{ config, lib, pkgs, ... }: with lib;
# Customer specific role

let
  cfg = config.flyingcircus.roles.webdata_blackbee;

  additional_hosts =
    if pathExists /srv/s-blackbee/hosts
    then readFile /srv/s-blackbee/hosts
    else "";

in
{

  options = {

    flyingcircus.roles.webdata_blackbee = {

      enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable the customer specific role.";
      };

    };

  };


  config = mkIf cfg.enable {

    environment.etc.blackbee.source = "/srv/s-blackbee/etc";

    system.activationScripts.webdata_blackbee = ''
      test -L /home/pricing || ln -s /srv/s-blackbee/pricing /home/pricing
      test -L /bin/bash || ln -s /run/current-system/sw/bin/bash /bin/bash
    '';

    networking.extraHosts = additional_hosts;

    environment.systemPackages = [
      pkgs.htop
      pkgs.innotop
      pkgs.mailx
      pkgs.mc
      pkgs.percona   # client is required on almost all nodes
      pkgs.sysbench
      pkgs.wget
    ];

    environment.shellAliases = {
        gopricing = "cd /home/pricing && sudo -u s-blackbee bash --login";
    };

    systemd.extraConfig = ''
      DefaultLimitNOFILE=64000
      DefaultLimitNPROC=64173
      DefaultLimitSIGPENDING=64173
    '';

  };

}
