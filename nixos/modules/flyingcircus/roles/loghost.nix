{ config, fclib, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.loghost;
  fclib = import ../lib;

  listenOn = head (fclib.listenAddresses config "ethsrv");
    loghostService = findFirst
    (s: s.service == "loghost-server")
    null
    config.flyingcircus.enc_services;

  serviceUser = "graylog";

  # -- files --
  rootPasswordFile = "/etc/local/graylog/password";
  rootPasswordSha2File = "/etc/local/graylog/password_sha2";
  passwordSecretFile = "/etc/local/graylog/password_secret";
  # -- passwords --
  generatedRootPassword = mkPassword "graylog.rootPassword";
  generatedRootPasswordSha2 = mkSha2 generatedRootPassword;
  generatedPasswordSecret = mkPassword "graylog.passwordSecret";

  rootPassword =
    fclib.configFromFile
      rootPasswordFile
      generatedRootPassword;

  rootPasswordSha2 =
    if cfg.rootPasswordSha2  == null
    then (fclib.configFromFile
            rootPasswordSha2File
            generatedRootPasswordSha2)
    else cfg.rootPasswordSha2;

  passwordSecret =
    if cfg.passwordSecret == null
    then (fclib.configFromFile
            passwordSecretFile
            generatedPasswordSecret)
    else cfg.passwordSecret;

  # -- helper functions --
  passwordActivation = file: password: user:
    let script = ''
     install -d -o ${toString config.ids.uids."${user}"} -g service -m 02775 \
        $(dirname ${file})
      if [[ ! -e ${file} ]]; then
        ( umask 007;
          echo ${password} > ${file}
          chown ${user}:service ${file}
        )
      fi
      chmod 0660 ${file}
    '';
    in script;

  mkPassword = identifier:
    removeSuffix "\n" (readFile
      (pkgs.runCommand identifier {}
        "${pkgs.apg}/bin/apg -a 1 -M lnc -n 1 -m 32 > $out")
      );

  mkSha2 = text:
    removeSuffix "\n" (readFile
      (pkgs.runCommand text {}
        "echo -n ${text} | sha256sum | cut -f1 -d \" \" > $out")
      );

in
{

  options = {

    flyingcircus.roles.loghost = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus graylog server role.";
      };

      rootPasswordSha2 = mkOption {
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
          (passwordActivation rootPasswordFile rootPassword serviceUser +
           passwordActivation rootPasswordSha2File rootPasswordSha2 serviceUser +
           passwordActivation passwordSecretFile passwordSecret serviceUser);

      services.graylog = {
      	enable = true;
  	    elasticsearchClusterName = "graylog";
        inherit passwordSecret rootPasswordSha2;
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
