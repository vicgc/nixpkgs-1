{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.flyingcircus.roles.loghost;
  fclib = import ../lib;

  listenOn = "127.0.0.1";
  serviceUser = "graylog";

  loghostService = findFirst
    (s: s.service == "loghost-server")
    null
    config.flyingcircus.enc_services;

  # -- files --
  rootPasswordFile = "/etc/local/graylog/password";
  passwordSecretFile = "/etc/local/graylog/password_secret";
  # -- passwords --
  generatedRootPassword = mkPassword "graylog.rootPassword";
  generatedPasswordSecret = mkPassword "graylog.passwordSecret";

  rootPassword = removeSuffix "\n"
    (if cfg.rootPassword  == null
    then (fclib.configFromFile
            rootPasswordFile
            generatedRootPassword)
    else cfg.rootPassword);

  rootPasswordSha2 = mkSha2 rootPassword;

  passwordSecret =
    if cfg.passwordSecret == null
    then (fclib.configFromFile
            passwordSecretFile
            generatedPasswordSecret)
    else cfg.passwordSecret;


  port = 9001;
  webListenUri = "http://${listenOn}:${toString port}/tools/${config.flyingcircus.enc.name}/graylog";
  restListenUri = "${webListenUri}/api";

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
      (pkgs.runCommand "dummy" { inherit text; }
        "echo -n $text | sha256sum | cut -f1 -d \" \" > $out")
      );

  logstashSSLHelper = with pkgs; writeScriptBin "logstash_ssl_import" ''
    #!${stdenv.shell}
    set -eu

    puppet="puppet.$FCIO_LOCATION.gocept.net"
    pw=$(${pwgen}/bin/pwgen -1 18)

    scp $puppet:/var/lib/puppet/lumberjack/keys/$FCIO_HOSTNAME.{crt,key} /var/lib/graylog/
    (cd /var/lib/graylog
     ${openssl}/bin/openssl pkcs12 -export -in $FCIO_HOSTNAME.crt \
                 -inkey $FCIO_HOSTNAME.key \
                 -out $FCIO_HOSTNAME.p12 \
                 -name $FCIO_HOSTNAME \
                 -passin pass:$pw \
                 -passout pass:$pw
     rm -f $FCIO_HOSTNAME.jks
     ${openjdk}/bin/keytool -importkeystore \
                 -srckeystore $FCIO_HOSTNAME.p12 \
                 -srcstoretype PKCS12\
                 -srcstorepass $pw \
                 -alias $FCIO_HOSTNAME \
                 -deststorepass $pw \
                 -destkeypass $pw \
                 -destkeystore $FCIO_HOSTNAME.jks
                 )
    echo "keystore: /var/lib/graylog/$FCIO_HOSTNAME.jks"
    echo "password: $pw"
  '';

  syslogPort = 5140;

  esNodes =
    ["${config.networking.hostName}.${config.networking.domain}:9350"
     "${config.networking.hostName}.${config.networking.domain}:9300"] ++
    map
      (service: "${service.address}:9300")
      (filter
        (s: s.service == "elasticsearch-node")
        config.flyingcircus.enc_services);

in
{

  options = {

    flyingcircus.roles.loghost = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus graylog server role.";
      };

      rootPassword = mkOption {
        type = types.nullOr types.string;
        default = null;
        description = ''
          The password for of your graylogs's webui root user. If null, a random password will be generated.
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

  config = mkMerge [
    (mkIf cfg.enable {

      environment.systemPackages = [ logstashSSLHelper ];

      networking.firewall.allowedTCPPorts = [ 9000 9002 ];

      flyingcircus.roles.nginx.enable = true;
      flyingcircus.roles.nginx.httpConfig =
      let
          listenOnPort = port: lib.concatMapStringsSep "\n    "
              (addr: "listen ${addr}:${port};")
              (fclib.listenAddressesQuotedV6 config "ethsrv");

          allow = ips: lib.concatMapStringsSep "\n    "
              (addr: "allow ${addr};")
              (ips);

      in
      ''
        server {
            ${listenOnPort "9000"}

            ${allow config.flyingcircus.static.directory.proxy_ips}
            deny all;

            location /tools/${config.flyingcircus.enc.name}/graylog {
                proxy_pass http://127.0.0.1:9001;
            }
          }

        server {
            ${listenOnPort "9002"}

            location /tools/${config.flyingcircus.enc.name}/graylog {
                proxy_pass http://127.0.0.1:9001;
                proxy_set_header REMOTE_USER "";
                proxy_set_header X-Graylog-Server-URL http://${config.networking.hostName}.${config.networking.domain}:9002/tools/${config.flyingcircus.enc.name}/graylog/api;
            }

            location = / {
              rewrite ^ /tools/${config.flyingcircus.enc.name}/graylog;
            }
          }
      '';

      system.activationScripts.fcio-loghost =
        stringAfter
          [ ]
          (passwordActivation rootPasswordFile rootPassword serviceUser +
           passwordActivation passwordSecretFile passwordSecret serviceUser);

      services.graylog = {
        enable = true;
        elasticsearchClusterName = "graylog";
        inherit passwordSecret rootPasswordSha2 webListenUri restListenUri;
        elasticsearchDiscoveryZenPingUnicastHosts =
          concatStringsSep "," esNodes;
        javaHeap = ''${toString
          (fclib.max [
            ((fclib.current_memory config 1024) * 15 / 100)
            1024
            ])}m'';
        extraConfig = ''
          trusted_proxies 127.0.0.1/8
          processbuffer_processors = ${toString
            (fclib.max [
              ((fclib.current_cores config 1) - 2)
              5])}
          outputbuffer_processors = ${toString
            (fclib.max [
              ((fclib.current_cores config 1) / 2)
              3])}
        '';
      };

      flyingcircus.roles.mongodb32.enable = true;
      flyingcircus.roles.elasticsearch = {
        enable = true;
        dataDir = "/var/lib/elasticsearch";
        clusterName = "graylog";
        heapPercentage = 35;
        esNodes = esNodes;
      };

      systemd.services.graylog-config = {
         description = "Enable Inputs for Graylog";
         requires = [ "graylog.service" ];
         after = [ "graylog.service" "mongodb.service" "elasticsearch.service" ];
         serviceConfig = {
           Type = "oneshot";
           User = config.services.graylog.user;
           RemainAfterExit = true;
         };
         script = let
           api = restListenUri;
           user = "admin";
           pw = rootPassword;

           input_body = {
             configuration = {
               bind_address = "0.0.0.0";
               expand_structured_data = false;
               force_rdns = false;
               recv_buffer_size = 262144;
               store_full_message =  false;
               allow_override_date =  true;
               port = syslogPort;
             };
             title = "Syslog UDP"; # be careful changing it, it's used as
                                   # a primary key for identifying the config
                                   # object
             type = "org.graylog2.inputs.syslog.udp.SyslogUDPInput";
             global = true;
           };
          sso_body = {
            default_group = "Admin";
            auto_create_user = true;
            username_header = "Remote-User";
            fullname_header = "X-Graylog-Fullname";
            email_header = "X-Graylog-Email";
            require_trusted_proxies = true;
            trusted_proxies = "127.0.0.1/8";
          };
        in
          ''${pkgs.fcmanage}/bin/fc-graylog \
          -u '${user}' \
          -p '${removeSuffix "\n" pw}' \
          '${api}' \
          '${builtins.toJSON input_body}' \
          '${builtins.toJSON sso_body}'
          '' ;
      };

      systemd.services.graylog-update-geolite = {
        description = "Update geolite db for graylog";
        restartIfChanged = false;
        after = [ "graylog.service" ];
        serviceConfig = {
          User = config.services.graylog.user;
          Type = "oneshot";
        };

        script = ''
          cd /var/lib/graylog
          ${pkgs.curl}/bin/curl -O http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz
          ${pkgs.gzip}/bin/gunzip -f GeoLite2-City.mmdb.gz
        '';
      };

      systemd.timers.graylog-update-geolite = {
        description = "Timer for updading the geolite db for graylog";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          Unit = "graylog-update-geolite.service";
          OnStartupSec = "10m";
          OnUnitActiveSec = "30d";
          # Not yet supported by our systemd version.
          # RandomSec = "3m";
        };
      };

      services.collectd.extraConfig = ''
        LoadPlugin curl_json
        <Plugin curl_json>
          <URL "${restListenUri}/system/journal">
            User "admin"
            Password "${rootPassword}"
            Header "Accept: application/json"
            Instance "graylog"
            <Key "uncommitted_journal_entries">
              Type "gauge"
            </Key>
            <Key "append_events_per_second">
              Type "gauge"
            </Key>
            <Key "read_events_per_second">
              Type "gauge"
            </Key>
          </URL>
          <URL "${restListenUri}/system/throughput">
            User "admin"
            Password "${rootPassword}"
            Header "Accept: application/json"
            Instance "graylog"
            <Key "throughput">
              Type "gauge"
            </Key>
          </URL>
        </Plugin>
      '';

    flyingcircus.services.sensu-client.checks = {
      graylog_ui = {
        notification = "Graylog UI alive";
        command = ''
          check_http -H ${listenOn} -p ${toString port} \
            -u /tools/${config.networking.hostName}/graylog/
        '';
      };
    };

    })
    # This configuration part defines loghosts clients as loghosts which happen to be their own clients as well
    (mkIf (loghostService != null) {
      services.rsyslogd.extraConfig = ''
        *.* @${loghostService.address}:${toString syslogPort};RSYSLOG_SyslogProtocol23Format
      '';
    }
    )];
  }
