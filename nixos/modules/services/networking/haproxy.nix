{ config, lib, pkgs, ... }:
let
  cfg = config.services.haproxy;
  haproxyCfg = pkgs.writeText "haproxy.conf" cfg.config;
in
with lib;
{
  options = {
    services.haproxy = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable HAProxy, the reliable, high performance TCP/HTTP
          load balancer.
        '';
      };

      config = mkOption {
        type = types.nullOr types.lines;
        default = null;
        description = ''
          Contents of the HAProxy configuration file,
          <filename>haproxy.conf</filename>.
        '';
      };

    };

  };

  config = mkIf cfg.enable {

    assertions = [{
      assertion = cfg.config != null;
      message = "You must provide services.haproxy.config.";
    }];

    systemd.services.haproxy = {
      description = "HAProxy";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        # FCIO Type = "forking";
        # FCIO PIDFile = "/run/haproxy.pid";
        # FCIO ExecStartPre = "${pkgs.haproxy}/sbin/haproxy -c -q -f ${haproxyCfg}";
        ExecStart = "${pkgs.haproxy}/sbin/haproxy -D -f ${haproxyCfg} -p /run/haproxy.pid";
        # FCIO ExecReload = "-${pkgs.bash}/bin/bash -c \"exec ${pkgs.haproxy}/sbin/haproxy -D -f ${haproxyCfg} -p /run/haproxy.pid -sf $MAINPID\"";
        RestartSec = "5s";
        StartLimitInterval = "1min";
      };
    };

    environment.systemPackages = [ pkgs.haproxy ];

    users.extraUsers.haproxy = {
      group = "haproxy";
      uid = config.ids.uids.haproxy;
    };

    users.extraGroups.haproxy.gid = config.ids.uids.haproxy;
  };
}
