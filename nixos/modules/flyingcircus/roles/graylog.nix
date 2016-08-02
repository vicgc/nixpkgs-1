{ config, lib, pkgs, ... }: with lib;

{

  options = {

    flyingcircus.roles.graylog = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus graylog server role.";
      };

    };

  };

  config = mkIf config.flyingcircus.roles.graylog.enable {


    services.graylog = {
    	enable = true;
	    passwordSecret = "admin";
	    rootPasswordSha2 = "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918";
	    elasticsearchClusterName = "graylog";
	    extraConfig = ''
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

  	flyingcircus.roles.webgateway.enable = true;
  	flyingcircus.roles.webproxy.enable = true;
  	flyingcircus.roles.mongodb.enable = true;
}