{ config, lib, pkgs, ... }: with lib;
let
  fclib = import ../lib;
  listenOn = head (fclib.listenAddresses config "ethsrv");

  loghostService = lib.findFirst
    (s: s.service == "loghost-server")
    null
    config.flyingcircus.enc_services;

  passwordSecret = fclib.generatePassword { serviceName = "graylog"; length = 96; };
  rootPasswordSha2 = builtins.elemAt (fclib.generatePasswordHash { serviceName = "graylog-webui"; length = 32; }) 1;

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

  config = mkMerge [

    (mkIf config.flyingcircus.roles.loghost.enable {
      # XXX Access should *onl* be allowed from directory and same-rg.
    	networking.firewall.allowedTCPPorts = [ 9000 ];

      services.graylog = {
        inherit passwordSecret rootPasswordSha2;
      	enable = true;
  	    elasticsearchClusterName = "graylog";
  	    extraConfig = ''
          # IPv6 would be nice, too :/
          web_listen_uri http://${listenOn}:9000/tools/${config.flyingcircus.enc.name}/graylog
          rest_listen_uri http://${listenOn}:9000/tools/${config.flyingcircus.enc.name}/graylog/api
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
    })
    (mkIf (loghostService != null) {
      services.rsyslogd.extraConfig = ''
        *.* @${loghostService.address}:5140;RSYSLOG_SyslogProtocol23Format
      '';
    })];
}
