{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.haproxy;
  fclib = import ../lib;

  haproxyCfgContent = fclib.configFromFile /etc/local/haproxy/haproxy.cfg cfg.haConfig;
  haproxyCfg = pkgs.writeText "haproxy.conf" config.services.haproxy.config;

  example = ''
    # haproxy configuration example - copy to haproxy.cfg and adapt.

    global
        daemon
        chroot /var/empty
        user haproxy
        group haproxy
        maxconn 4096
        log localhost local2
        stats socket ${cfg.statsSocket} mode 660 group nogroup level operator

    defaults
        mode http
        log global
        option httplog
        option dontlognull
        option http-server-close
        timeout connect 5s
        timeout client 30s    # should be equal to server timeout
        timeout server 30s    # should be equal to client timeout
        timeout queue 25s     # discard requests sitting too long in the queue

    listen http-in
        bind 127.0.0.1:8002
        bind ::1:8002
        default_backend be

    backend be
        server localhost localhost:8080
    '';

in
{

  options = {

    flyingcircus.roles.haproxy = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus haproxy server role.";
      };

      haConfig = mkOption {
        type = types.lines;
        default = example;
        description = "Full HAProxy configuration.";
      };

      statsSocket = mkOption {
        type = types.string;
        default = "/run/haproxy_admin.sock";
      };

    };

  };

  config = mkMerge [
    (mkIf config.flyingcircus.roles.haproxy.enable {

    services.haproxy.enable = true;
    services.haproxy.config = haproxyCfgContent;

   # FCIO
    systemd.services.haproxy = let
      haproxy_ = "${pkgs.haproxy}/bin/haproxy -f /etc/current-config/haproxy.cfg -p /run/haproxy.pid -Ws";
      verifyConfig = "${pkgs.haproxy}/bin/haproxy -c -q -f /etc/current-config/haproxy.cfg";
      in {
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
      preStart = ''
        install -d -o ${toString config.ids.uids.haproxy} -g service -m 02775 \
          /etc/local/haproxy
        ${verifyConfig};
      '';
      serviceConfig = {
        ExecStart = lib.mkOverride 90 haproxy_;
        KillMode = "mixed";
        Restart = "always";
      };

    };

    environment.etc = {
      "local/haproxy/README.txt".text = ''
        HAProxy is enabled on this machine.

        Put your haproxy configuration here as `haproxy.cfg`. There is also
        an example configuration here.
      '';
      "local/haproxy/haproxy.cfg.example".text = example;

      "current-config/haproxy.cfg".source = haproxyCfg;
    };

    flyingcircus.syslog.separateFacilities = {
      local2 = "/var/log/haproxy.log";
    };

    systemd.services.prometheus-haproxy-exporter = {
      description = "Prometheus exporter for haproxy metrics";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ pkgs.haproxy ];
      script = ''
        exec ${pkgs.prometheus-haproxy-exporter}/bin/haproxy_exporter \
          --web.listen-address localhost:9127 \
          --haproxy.scrape-uri=unix:${cfg.statsSocket}
      '';
      serviceConfig = {
        User = "nobody";
        Restart = "always";
        PrivateTmp = true;
        WorkingDirectory = /tmp;
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      };
    };

    services.telegraf.inputs = {
      prometheus  = [{
        urls = ["http://localhost:9127/metrics"];
      }];
    };
  })

  {
    flyingcircus.roles.statshost.globalAllowedMetrics = [ "haproxy" ];
  }
  ];
}
