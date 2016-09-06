{ config, lib, pkgs, ... }: with lib;
let
  fclib = import ../lib;
  listenOn = head (fclib.listenAddresses config "ethsrv");

  loghostService = lib.findFirst
    (s: s.service == "loghost-server")
    null
    config.flyingcircus.enc_services;
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
      # XXX only SRV actually. And maybe not at all.
    	networking.firewall.allowedTCPPorts = [ 9000 ];

      services.graylog = {
      	enable = true;
        # XXX move out of here
  	    passwordSecret = "gangland-daresay-polarize-celsius";
        # "admin"
  	    rootPasswordSha2 = "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918";
  	    elasticsearchClusterName = "graylog";
  	    extraConfig = ''
          # IPv6 would be nice, too :/
          web_listen_uri http://${listenOn}:9000/
          rest_listen_uri http://${listenOn}:9000/api
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
