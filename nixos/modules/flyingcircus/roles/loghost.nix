{ config, fclib, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.loghost;
  fclib = import ../lib;
  listenOn = head (fclib.listenAddresses config "ethsrv");

  loghostService = findFirst
    (s: s.service == "loghost-server")
    null
    config.flyingcircus.enc_services;

  # [password, hash]
  generatedPasswordWebUi = fclib.generatePasswordHash {
    serviceName = "graylog-webui";
    length = 32; };
  passwordWebUiHashed =
    if cfg.passwordWebUiHashed  == null
    then (fclib.configFromFile
            /etc/local/graylog-ui/passwordHash
            (builtins.elemAt generatedPasswordWebUi 1))
    else cfg.passwordWebUiHashed;
  passwordWebUi = builtins.elemAt generatedPasswordWebUi 0;

  # password
  generatedPasswordSecret = fclib.generatePassword {
    serviceName = "graylog";
    length = 96; };
  passwordSecret =
    if cfg.passwordSecret == null
    then (fclib.configFromFile /etc/local/graylog/password generatedPasswordSecret)
    else cfg.passwordSecret;
in
{

  options = {

    flyingcircus.roles.loghost = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus graylog server role.";
      };

      passwordWebUiHashed = mkOption {
        type = types.nullOr types.string;
        default = null;
        description = ''
          The sha256 hash of your graylogs's webui password. If null, a random hash will be generated.
        '';
      };

      passwordSecret = mkOption {
        type = types.nullOr types.string;
        default = null;
        description = ''
          A password secret for graylog. Use the same password secret fo the whole graylog
          cluster. If null, a random password will be generated.
        '';
      };
    };

  };

  config = mkIf cfg.enable {

      # XXX Access should *onl* be allowed from directory and same-rg.
    	networking.firewall.allowedTCPPorts = [ 9000 ];

      system.activationScripts.fcio-loghost =
        stringAfter
          [ ]
          (fclib.passwordActivation "graylog-webui" (toString config.ids.uids.graylog) passwordWebUiHashed +
          fclib.passwordActivation "graylog" (toString config.ids.uids.graylog) passwordSecret);

      services.graylog = {
      	enable = true;
  	    elasticsearchClusterName = "graylog";
        passwordSecret = passwordSecret;
        rootPasswordSha2 = passwordWebUiHashed;
        # ipv6 would be nice too
        webListenUri = "http://${listenOn}:9000/tools/${config.flyingcircus.enc.name}/graylog";
        restListenUri = "http://${listenOn}:9000/tools/${config.flyingcircus.enc.name}/graylog/api";
  	    extraConfig = ''
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
      # WIP: rest client
      # systemd.services.configure-inputs-for-graylog = {
      #   description = "Enable Inputs for Graylog";
      #   requires = [ "graylog.service" ];
      #   after = [ "graylog.service" ];
      #   serviceConfig = {
      #     Type = "oneshot";
      #     User = "graylog";
      #   };
      #   script = let
      #     curl = ''
      #       ${pkgs.curl}/bin/curl -s\
      #         -u "${services.graylog.rootUsername}:${passwordWebUi}" \
      #         -H "content-type:application/json" \
      #     '';
      #     api = services.graylog.restListenUri;
      #   }
      # }
    };
}
