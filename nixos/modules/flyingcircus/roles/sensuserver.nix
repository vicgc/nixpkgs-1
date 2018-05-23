{ config, lib, pkgs, ... }: with lib;

let
    hostname = "sensu.${config.flyingcircus.enc.parameters.location}.gocept.net";
in
{

    options = {

        flyingcircus.roles.sensuserver = {

            enable = mkOption {
                type = types.bool;
                default = false;
                description = "Enable the Flying Circus sensu server role.";
            };

        };

    };

    config = mkIf config.flyingcircus.roles.sensuserver.enable {

        flyingcircus.services.sensu-server.enable = true;
        flyingcircus.services.sensu-api.enable = true;
        flyingcircus.services.uchiwa.enable = true;

        flyingcircus.ssl.certificates = [ hostname ];

        flyingcircus.roles.nginx.enable = true;
        flyingcircus.roles.nginx.httpConfig = let
          # Use basic auth instead of real login until
          # https://github.com/sensu/uchiwa/issues/448 gets solved.
          admins = map (user: "${user}:${config.users.users."${user}".hashedPassword}") config.users.groups.admins.members;
          admins_htpasswd = builtins.toFile "admins.htpasswd" (concatStringsSep "\n" admins);
          in
          ''
          server {
            server_name ${hostname};
            listen 80;
            listen [::]:80;

            location / {
                rewrite (.*) https://$server_name$1 permanent;
             }
          }

          server {
            server_name ${hostname};
            listen 443;
            listen [::]:443;

            ssl on;
            ssl_certificate /etc/ssl/${hostname}.crt;
            ssl_certificate_key /etc/ssl/${hostname}.key;

            add_header Strict-Transport-Security "max-age=31536000";


            location / {
                proxy_pass http://localhost:3000;
                # https://github.com/sensu/uchiwa/issues/449
                # proxy_hide_header Authorization;
                auth_basic "Flying Circus";
                auth_basic_user_file ${admins_htpasswd};
            }

            # The trailing slashes are important to have nginx
            # strip the leading /api and the API is not vhost
            # compatible, thus needs this removed.
            location /api/ {
                proxy_pass http://127.0.0.1:8002/;
            }

          }
        '';

    };
}
