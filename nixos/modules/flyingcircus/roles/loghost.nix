{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.loghost;
  fclib = import ../lib;
  listenOn = head (fclib.listenAddresses config "ethsrv");

  loghostService = findFirst
    (s: s.service == "loghost-server")
    null
    config.flyingcircus.enc_services;

  admin_password_file = "/etc/local/loghost/graylog-webui.admin_passwd";
  admin_password_setter =
    if cfg.adminPassword == null
    then "$(${pkgs.apg}/bin/apg -a 1 -M lnc -n 1 -m 12)"
    else "\"${cfg.adminPassword}\"";

  password_secret_file = "/etc/local/loghost/graylog.passwd_secret";
  password_secret_setter =
    if cfg.passwordSecret == null
    then "$(${pkgs.apg}/bin/apg -a 1 -M lnc -n 1 -m 96)"
    else "\"${cfg.passwordSecret}\"";
in
{

  options = {

    flyingcircus.roles.loghost = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus graylog server role.";
      };

    };

  };

  config = mkIf cfg.enable {

      # XXX Access should *onl* be allowed from directory and same-rg.
    	networking.firewall.allowedTCPPorts = [ 9000 ];

      system.activationScripts.loghost-init =
        stringAfter
          [ ]
          ''
            install -d -o graylog -g service -m 02775 /etc/local/loghost/

            umask 0066
            if [[ ! -f ${admin_password_file} ]]; then
              pw=${admin_password_setter}
              echo -n "''${pw}" > ${admin_password_file}
              echo "''${pw}" | sha256sum | cut -f1 -d " " >> ${admin_password_file}
            fi
            if [[ ! -f ${password_secret_file} ]]; then
              pw=${password_secret_setter}
              echo -n "''${pw}" > ${password_secret_file}
            fi
          '';

      services.graylog = {
      	enable = true;
  	    elasticsearchClusterName = "graylog";
        passwordSecret = readFile password_secret_file;
  	    extraConfig = ''
          # IPv6 would be nice, too :/
          web_listen_uri http://[::]:9000/tools/${config.flyingcircus.enc.name}/graylog
          rest_listen_uri http://[::]:9000/tools/${config.flyingcircus.enc.name}/graylog/api
          trusted_proxies 195.62.125.243/32, 195.62.125.11/32, 172.22.49.56/32
  	    '';
    	};

    	services.elasticsearch2 = {
      	enable = true;
      	cluster_name = "graylog";
      	extraConf = ''
          discovery_zen_ping_multicast_enabled : false
          # List of Elasticsearch nodes to connect to
          elasticsearch_discovery_zen_ping_unicast_hosts : localhost:9300
        '';
    	};
    	flyingcircus.roles.mongodb.enable = true;

      services.rsyslogd.extraConfig = ''
        *.* @${loghostService.address}:5140;RSYSLOG_SyslogProtocol23Format
      '';
    };
}
