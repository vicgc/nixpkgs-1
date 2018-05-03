# Relay stats of a location via NGINX
{ config, lib, pkgs, ... }:
with lib;
let
  fclib = import ../../lib;
  # This doesn't work, because it returns the SRV name, we need FE.
  # statshostService = lib.findFirst
  #   (s: s.service == "statshost-collector")
  #   null
  #   config.flyingcircus.enc_services;
  statshostService = "stats.flyingcircus.io";
  port = 9090;
in
{
  config = mkIf (
      config.flyingcircus.roles.statshostproxy.enable &&
      statshostService != null) {

    networking.firewall.extraCommands = ''
      ip46tables -A nixos-fw -i ethfe -s ${statshostService} \
        -p tcp --dport ${toString port} -j nixos-fw-accept
    '';

    flyingcircus.roles.nginx.enable = true;
    flyingcircus.roles.nginx.httpConfig = ''
      server {
        # XXX HTTPS!
        ${fclib.nginxListenOn config "ethfe" port}

        access_log /var/log/nginx/statshost_access.log;
        error_log /var/log/nginx/statshost_error.log;

        location / {
            resolver ${concatStringsSep " " config.networking.nameservers};
            proxy_pass http://$http_host$request_uri$is_args$args;
            proxy_bind ${head (fclib.listenAddresses config "ethsrv")};
        }
      }
    '';

  };
}
