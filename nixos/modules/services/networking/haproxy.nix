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

    # FCIO
    systemd.services.haproxy = let
      haproxy_ = "${pkgs.haproxy}/sbin/haproxy-systemd-wrapper -f /etc/haproxy.cfg -p /run/haproxy.pid";
      verifyConfig = "${pkgs.haproxy}/sbin/haproxy -c -q -f /etc/haproxy.cfg";
      in {
      description = "HAProxy";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      reloadIfChanged = true;
      restartTriggers = [ haproxyCfg ];
      reload = ''
        if ${pkgs.procps}/bin/pgrep -f '${haproxy_}'
        then
          ${verifyConfig} && ${pkgs.coreutils}/bin/kill -USR2 $MAINPID
        else
          echo "Binary or parameters changed. Restarting."
          systemctl restart haproxy
        fi
      '';
      preStart = verifyConfig;
      serviceConfig = {
        ExecStart = haproxy_;
        KillMode = "mixed";
        Restart = "always";
      };
    };

    # FCIO:
    environment.etc."haproxy.cfg".source = haproxyCfg;

    environment.systemPackages = [ pkgs.haproxy ];

    users.extraUsers.haproxy = {
      group = "haproxy";
      uid = config.ids.uids.haproxy;
    };

    users.extraGroups.haproxy.gid = config.ids.uids.haproxy;
  };
}
