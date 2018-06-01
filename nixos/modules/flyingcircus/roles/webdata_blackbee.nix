{ config, lib, pkgs, ... }: with lib;
# Customer specific role

let
  fclib = import ../lib;
  cfg = config.flyingcircus.roles.webdata_blackbee;


  firewallTrustedSSH = [
    # VPN prod
    "172.22.49.50"
    "2a02:248:101:63::1189"
    "2a02:248:101:62::1180"
    "2a02:248:101:62::1190"
    "195.62.126.67"

    # VPN stag
    "172.22.49.52"
    "2a02:248:101:63::118b"
    "195.62.126.68"
    "2a02:248:101:62::1182"
    "2a02:248:101:62::118f"

    # Azure prod/stag
    "192.168.203.0/24"
    "192.168.204.0/24"
  ];

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
      pkgs.sshpass
      pkgs.sysbench
      pkgs.wget
    ];

    environment.shellAliases = {
        gopricing = "cd /home/pricing && sudo -u s-blackbee bash --login";
        more = "less -e";
    };

    systemd.extraConfig = ''
      DefaultLimitNOFILE=64000
      DefaultLimitNPROC=64173
      DefaultLimitSIGPENDING=64173
    '';

    networking.firewall.extraCommands = let
      allowed = concatStringsSep "\n"
        (map
          (ip: ''
            ${fclib.iptables ip} -A nixos-fw -s ${ip} -p tcp --dport 22 \
              -j nixos-fw-accept
          '')
          (config.flyingcircus.static.firewall.trusted ++ firewallTrustedSSH));
    in

    ''
      # Counter previous ssh allow rule
      ip46tables -D nixos-fw -p tcp --dport ssh -j nixos-fw-accept || true
      # Allow ssh from trusted nets/hosts
      ${allowed}
    '';

  };
}
