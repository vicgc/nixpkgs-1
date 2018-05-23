{ config, pkgs, lib, ... }:

with lib;

let

  sensu = pkgs.sensu;

  cfg = config.flyingcircus.services.sensu-api;

  # Duplicated from server.nix.
  sensu_clients = filter
    (x: x.service == "sensuserver-server")
    config.flyingcircus.enc_service_clients;

  server_password = (lib.findSingle
    (x: x.node == "${config.networking.hostName}.gocept.net")
    { password = ""; } { password = ""; } sensu_clients).password;

  api_password = (lib.findSingle
    (x: x.service == "sensuserver-api" &&
        x.address == "${config.networking.hostName}.gocept.net")
    { password = ""; } { password = ""; } config.flyingcircus.enc_services).password;

  sensu_api_json = pkgs.writeText "sensu-api.json"
    ''
    {
      "rabbitmq": {
        "host": "${config.networking.hostName}.gocept.net",
        "user": "sensu-server",
        "password": "${server_password}",
        "vhost": "/sensu"
      },
      "api": {
        "user": "sensuserver-api",
        "password": "${api_password}"
      }
    }
    '';

in  {

  options = {

    flyingcircus.services.sensu-api = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable the Sensu monitoring API daemon.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    users.extraGroups.sensuapi.gid = config.ids.gids.sensuapi;

    users.extraUsers.sensuapi = {
      description = "sensu api daemon user";
      uid = config.ids.uids.sensuapi;
      group = "sensuapi";
    };

    services.rabbitmq.enable = true;
    services.redis.enable = true;

    # This is a bit of a hack at the moment ...
    flyingcircus.roles.haproxy.enable = true;
    flyingcircus.roles.haproxy.haConfig = ''
      # haproxy configuration example - copy to haproxy.cfg and adapt.

      global
          daemon
          chroot /var/empty
          user haproxy
          group haproxy
          maxconn 4096
          log localhost local2
          stats socket ${config.flyingcircus.roles.haproxy.statsSocket} mode 660 group nogroup level operator

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
          default_backend sensu_api

      backend sensu_api
          server localhost localhost:4567 maxconn 1
    '';

    systemd.services.sensu-api = {
      wantedBy = [ "multi-user.target" ];
      requires = [
        "rabbitmq.service"
        "redis.service"];
      path = [ sensu ];
      serviceConfig = {
        User = "sensuapi";
        ExecStart = "${sensu}/bin/sensu-api -L warn -c ${sensu_api_json}";
        Restart = "always";
        RestartSec = "5s";
      };
    };

  };

}
