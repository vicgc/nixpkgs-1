{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.nginx;
  nginx = cfg.package;
  configFile = pkgs.writeText "nginx.conf" ''
    user ${cfg.user} ${cfg.group};
    daemon off;

    ${cfg.config}

    ${optionalString (cfg.httpConfig != "") ''
    http {
      include ${cfg.package}/conf/mime.types;
      ${cfg.httpConfig}
    }
    ''}
    ${cfg.appendConfig}
  '';
in

{
  options = {
    services.nginx = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = "
          Enable the nginx Web Server.
        ";
      };

      package = mkOption {
        default = pkgs.nginx;
        type = types.package;
        description = "
          Nginx package to use.
        ";
      };

      config = mkOption {
        default = "events {}";
        description = "
          Verbatim nginx.conf configuration.
        ";
      };

      appendConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Configuration lines appended to the generated Nginx
          configuration file. Commonly used by different modules
          providing http snippets. <option>appendConfig</option>
          can be specified more than once and it's value will be
          concatenated (contrary to <option>config</option> which
          can be set only once).
        '';
      };

      httpConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Configuration lines to be appended inside of the http {} block.";
      };

      stateDir = mkOption {
        default = "/var/spool/nginx";
        description = "
          Directory holding all state for nginx to run.
        ";
      };

      user = mkOption {
        type = types.str;
        default = "nginx";
        description = "User account under which nginx runs.";
      };

      group = mkOption {
        type = types.str;
        default = "nginx";
        description = "Group account under which nginx runs.";
      };

    };

  };

  config = mkIf cfg.enable {
    # TODO: test user supplied config file pases syntax test

    # FCIO: Use reload instead of restart.
    systemd.services.nginx =
      let nginx_ = "${nginx}/bin/nginx -c /etc/nginx.conf -p ${cfg.stateDir}";
      in {
      description = "Nginx Web Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ nginx ];
      reloadIfChanged = true;
      restartTriggers = [ configFile ];
      preStart =
        ''
        mkdir -p ${cfg.stateDir}/logs
        chmod 700 ${cfg.stateDir}
        chown -R ${cfg.user}:${cfg.group} ${cfg.stateDir}
        '';
      # Is nginx is already running with a fixed config file location?
      reload = ''
        if systemctl status nginx | \
          grep -v grep | grep -q 'master process .* -c /etc/nginx.conf'
        then
          ${nginx_} -t && ${nginx_} -s reload
        else
          echo "config file location changed"
          systemctl restart nginx
        fi
      '';
      serviceConfig = {
        ExecStart = "${nginx_}";
        Restart = "on-failure";
        RestartSec = "10s";
        StartLimitInterval = "1min";
      };
    };

    # FCIO
    environment.etc."nginx.conf".source = configFile;

    users.extraUsers = optionalAttrs (cfg.user == "nginx") (singleton
      { name = "nginx";
        group = cfg.group;
        uid = config.ids.uids.nginx;
      });

    users.extraGroups = optionalAttrs (cfg.group == "nginx") (singleton
      { name = "nginx";
        gid = config.ids.gids.nginx;
      });
  };
}
