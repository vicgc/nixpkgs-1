{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus;
  fclib = import ../lib;

  localConfig = if pathExists /etc/local/nginx
  then "include ${/etc/local/nginx}/*.conf;"
  else "";

  baseConfig = ''
    worker_processes ${toString (fclib.current_cores config 1)};
    worker_rlimit_nofile 8192;

    error_log stderr;

    events {
      worker_connections 4096;
      multi_accept on;
    }

    http {
      include ${config.services.nginx.package}/conf/mime.types;
      default_type application/octet-stream;
      charset UTF-8;

      map_hash_bucket_size 64;

      map $remote_addr $remote_addr_anon_head {
        default 0.0.0;
        "~(?P<ip>\d+\.\d+\.\d+)\.\d+" $ip;
        "~(?P<ip>[^:]+:[^:]+:[^:]+):" $ip;
      }

      map $remote_addr $remote_addr_anon_tail {
        default .0;
        "~(?P<ip>\d+\.\d+\.\d+)\.\d+" .0;
        "~(?P<ip>[^:]+:[^:]+:[^:]+):" ::;
      }

      map $remote_addr_anon_head$remote_addr_anon_tail $remote_addr_anon {
          default 0.0.0.0;
          "~(?P<ip>.*)" $ip;
      }

      # same as 'anonymized'
      log_format main
          '$remote_addr_anon - $remote_user [$time_local] '
          '"$request" $status $bytes_sent '
          '"$http_referer" "$http_user_agent" '
          '"$gzip_ratio"';

      log_format anonymized
          '$remote_addr_anon - $remote_user [$time_local] '
          '"$request" $status $body_bytes_sent '
          '"$http_referer" "$http_user_agent" '
          '"$gzip_ratio"';

      log_format nonanonymized
          '$remote_addr - $remote_user [$time_local] '
          '"$request" $status $bytes_sent '
          '"$http_referer" "$http_user_agent" '
          '"$gzip_ratio"';

      log_format performance
          '$time_iso8601 $pid.$connection.$connection_requests '
          '$request_method "$scheme://$host$request_uri" $status '
          '$bytes_sent $request_length $pipe $request_time '
          '"$upstream_response_time" $gzip_ratio';

      open_log_file_cache max=64;
      access_log /var/log/nginx/access.log anonymized;
      access_log /var/log/nginx/performance.log performance;

      client_header_timeout 10m;
      client_body_timeout 10m;
      send_timeout 10m;

      connection_pool_size 256;
      client_header_buffer_size 4k;
      large_client_header_buffers 4 16k;
      request_pool_size 4k;

      gzip on;
      gzip_min_length 1100;
      gzip_types application/javascript application/json
          application/vnd.ms-fontobject application/x-javascript
          application/xml application/xml+rss font/opentype font/truetype
          image/svg+xml text/css text/javascript text/plain text/xml;
      gzip_vary on;
      gzip_disable msie6;
      gzip_proxied any;

      sendfile on;
      tcp_nopush on;
      tcp_nodelay on;

      keepalive_timeout 75 20;
      reset_timedout_connection on;
      server_names_hash_bucket_size 128;
      server_names_hash_max_size 1024;
      ignore_invalid_headers on;

      index index.html;
      root /var/www/localhost/htdocs;

      client_max_body_size 25m;

      proxy_buffers 8 32k;
      proxy_buffer_size 32k;
      proxy_http_version 1.1;
      proxy_read_timeout 120;
      proxy_set_header Connection "";
      proxy_set_header Host $http_host;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Port $server_port;
      proxy_set_header X-Forwarded-Scheme $scheme;
      proxy_set_header X-Nginx-Id '$pid.$connection.$connection_requests';

      fastcgi_buffers 64 4k;
      fastcgi_keep_conn on;

      # http://blog.zachorr.com/nginx-setup/
      open_file_cache max=1000 inactive=20s;
      open_file_cache_valid 30s;
      open_file_cache_min_uses 2;
      open_file_cache_errors on;

      # http://www.kuketz-blog.de/nsa-abhoersichere-ssl-verschluesselung-fuer-apache-und-nginx/
      ssl_prefer_server_ciphers on;
      ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
      ssl_ciphers "EECDH+AESGCM EDH+AESGCM EECDH EDH RSA+3DES -RC4 -aNULL -eNULL -LOW -MD5 -EXP -PSK -DSS -ADH";
      ssl_session_cache shared:SSL:10m;
      ssl_session_timeout 10m;
      ssl_dhparam /etc/ssl/dhparams.pem;

      # Server Status for monitoring:
      server {
        listen 127.0.0.1:80 default_server;
        listen [::1]:80 default_server;
        access_log off;
        server_name _;
        server_name_in_redirect off;

        location /nginx_status {
          stub_status on;
          access_log   off;
          allow 127.0.0.1;
          allow ::1;
          deny all;
         }
      }

      ${localConfig}

      ${config.flyingcircus.roles.nginx.httpConfig}
    }
  '';

in
{

  options = {

    flyingcircus.roles.nginx = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus nginx server role.";
      };

      httpConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Configuration lines to be appended inside of the http {} block.";
      };

    };

  };

  config =
  with lib;
  let
    htpasswdUsers = optionalString
      (config.users.groups ? login)
      (builtins.concatStringsSep "\n"
        (map
         (user: "${user.name}:${user.hashedPassword}")
         (builtins.filter
          (user: (builtins.stringLength user.hashedPassword) > 0)
          (map
           (username: config.users.users.${username})
           (config.users.groups.login.members)))));

    listenStatements =
      builtins.concatStringsSep "\n    "
        (concatMap
          (formatted_addr: [
            "listen ${formatted_addr}:80;"
            "listen ${formatted_addr}:443 ssl;"])
          (map
            (addr:
              if fclib.isIp4 addr
              then addr
              else "[${addr}]")
            (fclib.listenAddresses config "ethfe")));

  in mkMerge [
    (mkIf cfg.roles.nginx.enable {

    services.nginx.enable = true;
    services.nginx.config = "";
    services.nginx.appendConfig = baseConfig;

    # XXX only on FE!
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    system.activationScripts.nginx = ''
      install -d -o ${toString config.ids.uids.nginx} /var/log/nginx
      install -d -o ${toString config.ids.uids.nginx} -g service -m 02775 /etc/local/nginx
    '';

    services.logrotate.config = ''
        /var/log/nginx/*access*log
        /var/log/nginx/*error*log
        /var/log/nginx/performance.log
        {
            rotate 92
            create 0644 nginx service
            postrotate
                systemctl kill nginx -s USR1 --kill-who=main
            endscript
        }
    '';

    services.telegraf.inputs = {
      nginx = [{
        urls = ["http://localhost:80/nginx_status"];
      }];
    };


    environment.etc = {

      "local/nginx/README.txt".text = ''
        Nginx is enabled on this machine.

        Put your site configuration into this directory as `*.conf`. You may
        add other files, like SSL keys, as well.

        If you want to authenticate against the Flying Circus users with login permission,
        use the following snippet, and *USE SSL*:

          auth_basic "FCIO user";
          auth_basic_user_file "/etc/local/nginx/htpasswd_fcio_users";

        There is also an `example-configuration` here.

      '';

      "local/nginx/fastcgi_params" = {
        source = "${pkgs.nginx}/conf/fastcgi_params";
      };

      "local/nginx/uwsgi_params" = {
        source = "${pkgs.nginx}/conf/uwsgi_params";
      };

      "local/nginx/example-configuration".text = ''
        # Example nginx configuration for the Flying Circus. Copy this file into
        # 'mydomain.conf' and edit. You'll certainly want to replace www.example.com
        # with something more specific. Please note that configuration files must end
        # with '.conf' to be active. Reload with `sudo fc-manage --build`.

        upstream @varnish {
            server localhost:8008;
            keepalive 100;
        }

        upstream @haproxy {
            server localhost:8002;
            keepalive 10;
        }

        upstream @app {
            server localhost:8080;
        }

        server {
            ${listenStatements}

            # The first server name listed is the primary name. We remommend against
            # using a wildcard server name (*.example.com) as primary.
            server_name www.example.com example.com;

            # Redirect to primary server name (makes URLs unique).
            if ($host != $server_name) {
                rewrite . $scheme://$server_name$request_uri redirect;
            }

            # Enable SSL. SSL parameters like cipher suite have sensible defaults.
            #ssl_certificate /etc/nginx/local/www.example.com.crt;
            #ssl_certificate_key /etc/nginx/local/www.example.com.key;

            # Enable the following block if you want to serve HTTPS-only.
            #if ($server_port != 443) {
            #    rewrite . https://$server_name$request_uri redirect;
            #}
            #add_header Strict-Transport-Security max-age=31536000;

            location / {
                # Example for passing virtual hosting details to Zope apps
                #rewrite (.*) /VirtualHostBase/http/$server_name:$server_port/APP/VirtualHostRoot$1 break;
                #proxy_pass http://@varnish;

                # enable mod_security - custom mod_security configuration should go into
                # /etc/nginx/modsecurity/local.conf
                #ModSecurityEnabled on;
                #ModSecurityConfig /etc/nginx/modsecurity/modsecurity.conf;
            }
        }
        '';

      "local/nginx/htpasswd_fcio_users" = {
        text = htpasswdUsers;
        uid = config.ids.uids.nginx;
        mode = "0440";
      };

      "nginx/local" = {
        source = "/etc/local/nginx";
        enable = cfg.compat.gentoo.enable;
      };
      "nginx/fastcgi_params" = {
        source = "/etc/local/nginx/fastcgi_params";
        enable = cfg.compat.gentoo.enable;
      };
    };
  })

  {
    flyingcircus.roles.statshost.globalAllowedMetrics = [ "nginx" ];
  }
  ];
}
