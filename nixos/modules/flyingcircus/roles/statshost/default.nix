# statshost: an InfluxDB/Grafana server. Accepts incoming graphite traffic,
# stores it and renders graphs.
{ config, lib, pkgs, ... }:

with lib;
with builtins;

let
  fclib = import ../../lib;

  # For details, see the option description below
  cfgStatsGlobal = config.flyingcircus.roles.statshost;
  cfgStatsRG = config.flyingcircus.roles.statshost-master;
  cfgProxyGlobal = config.flyingcircus.roles.statshostproxy;
  cfgProxyRG = config.flyingcircus.roles.statshost-relay;

  promFlags = [
    "-storage.local.retention ${toString (cfgStatsGlobal.prometheusRetention * 24)}h"
    "-storage.local.series-file-shrink-ratio 0.3"
    "-storage.local.target-heap-size=${toString prometheusHeap}"
    "-storage.local.chunk-encoding-version=2"
  ];
  prometheusListenAddress = cfgStatsGlobal.prometheusListenAddress;
  prometheusHeap =
    (fclib.current_memory config 256) * 1024 * 1024
    * cfgStatsGlobal.prometheusHeapMemoryPercentage / 100;

  # It's common to have stathost and loghost on the same node. Each should
  # use half of the memory then. A general approach for this kind of
  # multi-service would be nice.
  heapCorrection =
    if config.flyingcircus.roles.loghost.enable
    then 50
    else 100;

  customRelabelPath = "/etc/local/statshost/metric-relabel.yaml";
  customRelabelConfig = relabelConfiguration customRelabelPath;
  customRelabelJSON = filename:
    pkgs.runCommand "${baseNameOf filename}.json" {
      buildInputs = [ pkgs.remarshal ];
      preferLocalBuild = true;
    } "remarshal -if yaml -of json < ${/. + filename} > $out";

  relabelConfiguration = filename:
    if pathExists filename
    then fromJSON (readFile (customRelabelJSON filename))
    else [];


  prometheusMetricRelabel =
    cfgStatsGlobal.prometheusMetricRelabel ++ customRelabelConfig;

  relayRGNodes =
    fclib.jsonFromFile "/etc/local/statshost/relays.json" "[]";

  relayLocationNodes = map
    (proxy: { job_name = proxy.location;
              proxy_url = "http://${proxy.address}:9090"; })
    relayLocationProxies;
  relayLocationProxies =
    # We need the FE address, which is not published by directory. I'd think
    # "interface" should become an attribute in the services table.
    let
      makeFE = s: "${(removeSuffix ".gocept.net" s.address)}.fe.${s.location}.gocept.net";
    in
  map
    (service: service // { address = makeFE service; })
    (filter
      (s: s.service == "statshostproxy-location")
      config.flyingcircus.enc_services);


  buildRelayConfig = relayNodes: nodeConfig: map
    (relayNode: {
        scrape_interval = "15s";
        file_sd_configs = [
          {
            files = [ (nodeConfig relayNode)];
            refresh_interval = "10m";
          }
        ];
        metric_relabel_configs =
          prometheusMetricRelabel ++
          (relabelConfiguration "/etc/local/statshost/metric-relabel.${relayNode.job_name}.yaml");
      } // relayNode)
      relayNodes;

    relayRGConfig = buildRelayConfig
      relayRGNodes
      (relayNode: "/var/cache/statshost-relay-${relayNode.job_name}.json");

    relayLocationConfig = buildRelayConfig
      relayLocationNodes
      (relayNode: "/etc/current-config/statshost-relay-${relayNode.job_name}.json");

  statshostService = lib.findFirst
    (s: s.service == "statshost-collector")
    null
    config.flyingcircus.enc_services;

  grafanaLdapConfig = pkgs.writeText "ldap.toml" ''
    verbose_logging = true

    [[servers]]
    host = "ldap.rzob.gocept.net"
    port = 389
    start_tls = true
    bind_dn = "uid=%s,ou=People,dc=gocept,dc=com"
    search_base_dns = ["ou=People,dc=gocept,dc=com"]
    search_filter = "(&(&(objectClass=inetOrgPerson)(uid=%s))(memberOf=cn=${config.flyingcircus.enc.parameters.resource_group},ou=GroupOfNames,dc=gocept,dc=com))"
    group_search_base_dns = ["ou=Group,dc=gocept,dc=com"]
    group_search_filter = "(&(objectClass=posixGroup)(memberUid=%s))"

    [servers.attributes]
    name = "cn"
    surname = "displaname"
    username = "uid"
    member_of = "cn"
    email = "mail"

    [[servers.group_mappings]]
    group_dn = "${config.flyingcircus.enc.parameters.resource_group}"
    org_role = "Admin"

  '';
  grafanaJsonDashboardPath = "${config.services.grafana.dataDir}/dashboards";

in
{

  imports = [
    ./global-relabel.nix
    ./location-relay.nix
    ./rg-relay.nix
  ];

  options = {

    # The following two roles are *system/global* roles for FC use.
    flyingcircus.roles.statshost = {
      enable = mkEnableOption "Grafana/InfluxDB stats host (global)";

      useSSL = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enables SSL in the virtual host.

          Expects the SSL certificates and keys to be placed in
          /etc/local/nginx/stats.crt and /etc/local/nginx/stats.key
        '';
      };

      hostName = mkOption {
        type = types.str;
        description = "HTTP host name for the stats frontend. Must be set.";
        example = "stats.example.com";
        default = config.networking.hostName;
      };

      prometheusMetricRelabel = mkOption {
        type = types.listOf types.attrs;
        default = [];
        description = "Prometheus metric relabel configuration.";
      };

      dashboardsRepository = mkOption {
        type = types.str;
        default = "https://github.com/flyingcircusio/grafana.git";
        description = "Dashboard git repository.";
      };

      prometheusListenAddress = mkOption {
        type = types.str;
        default = "${lib.head(fclib.listenAddressesQuotedV6 config "ethsrv")}:9090";
        description = "Prometheus listen address";
      };

      prometheusHeapMemoryPercentage = mkOption {
        type = types.int;
        default = 66 * heapCorrection / 100;
        description = "How much RAM should go to prometheus heap.";
      };

      prometheusRetention = mkOption {
        type = types.int;
        default = 70;
        description = "How long to keep data in *days*.";
      };

      globalAllowedMetrics = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          List of globally allowed metric prefixes. Metrics not matching the
          prefix will be droped on the *central* prometheus. This is useful
          to avoid indexing customer metrics, which have no meaning for us
          anyway.
        '';
      };

    };

    flyingcircus.roles.statshostproxy = {
      enable = mkEnableOption "Stats proxy, which relays an entire location";
    };


    # The following two roles are "customer" roles, customers can use them to
    # have their own statshost.
    flyingcircus.roles.statshost-master = {
      enable = mkEnableOption "Grafana/Prometheus stats host for one RG";
    };

    flyingcircus.roles.statshost-relay = {
      enable = mkEnableOption "RG-specific Grafana/Prometheus stats relay";
    };

  };

  config = mkMerge [

    # Global stats host. Currently influxdb *and* prometheus
    (mkIf cfgStatsGlobal.enable {

      # make the 'influx' command line tool accessible
      environment.systemPackages = [ pkgs.influxdb ];

      services.influxdb011.enable = true;
      services.influxdb011.dataDir = "/srv/influxdb";
      services.influxdb011.package = pkgs.influxdb;

      services.influxdb011.extraConfig = {
        http.enabled = true;
        http.auth-enabled = false;

        graphite = [
          { enabled = true;
            protocol = "udp";
            udp-read-buffer = 8388608;
            templates = [
              # new hierarchy
              "fcio.*.*.*.*.*.ceph .location.resourcegroup.machine.profile.host.measurement.instance..field"
              "fcio.*.*.*.*.*.cpu  .location.resourcegroup.machine.profile.host.measurement.instance..field"
              "fcio.*.*.*.*.*.load .location.resourcegroup.machine.profile.host.measurement..field"
              "fcio.*.*.*.*.*.netlink .location.resourcegroup.machine.profile.host.measurement.instance.field*"
              "fcio.*.*.*.*.*.entropy .location.resourcegroup.machine.profile.host.measurement.field"
              "fcio.*.*.*.*.*.swap .location.resourcegroup.machine.profile.host.measurement..field"
              "fcio.*.*.*.*.*.uptime .location.resourcegroup.machine.profile.host.measurement.field"
              "fcio.*.*.*.*.*.processes .location.resourcegroup.machine.profile.host.measurement.field*"
              "fcio.*.*.*.*.*.users .location.resourcegroup.machine.profile.host.measurement.field"
              "fcio.*.*.*.*.*.vmem .location.resourcegroup.machine.profile.host.measurement..field"
              "fcio.*.*.*.*.*.disk .location.resourcegroup.machine.profile.host.measurement.instance.field*"
              "fcio.*.*.*.*.*.interface .location.resourcegroup.machine.profile.host.measurement.instance.field*"
              "fcio.*.*.*.*.*.postgresql .location.resourcegroup.machine.profile.host.measurement.instance.field*"
              "fcio.*.*.*.*.*.*.memory .location.resourcegroup.machine.profile.host.measurement..field*"
              "fcio.*.*.*.*.*.curl_json.*.*.* .location.resourcegroup.machine.profile.host..measurement..field*"
              "fcio.*.*.*.*.*.df.*.df_complex.* .location.resourcegroup.machine.profile.host.measurement.instance..field"
              "fcio.*.*.*.*.*.conntrack.* .location.resourcegroup.machine.profile.host.measurement.field*"
              "fcio.*.*.*.*.*.tail.* .location.resourcegroup.machine.profile.host..measurement.field*"

              # Generic collectd plugin: measurement/instance/field (i.e. load/loadl/longtermn)
              "fcio.* .location.resourcegroup.machine.profile.host.measurement.field*"

              # old hierarchy
              "fcio.*.*.*.ceph .location.resourcegroup.host.measurement.instance..field"
              "fcio.*.*.*.cpu  .location.resourcegroup.host.measurement.instance..field"
              "fcio.*.*.*.load .location.resourcegroup.host.measurement..field"
              "fcio.*.*.*.netlink .location.resourcegroup.host.measurement.instance.field*"
              "fcio.*.*.*.entropy .location.resourcegroup.host.measurement.field"
              "fcio.*.*.*.swap .location.resourcegroup.host.measurement..field"
              "fcio.*.*.*.uptime .location.resourcegroup.host.measurement.field"
              "fcio.*.*.*.processes .location.resourcegroup.host.measurement.field*"
              "fcio.*.*.*.users .location.resourcegroup.host.measurement.field"
              "fcio.*.*.*.vmem .location.resourcegroup.host.measurement..field"
              "fcio.*.*.*.disk .location.resourcegroup.host.measurement.instance.field*"
              "fcio.*.*.*.interface .location.resourcegroup.host.measurement.instance.field*"
            ];
          }
        ];
      };

      boot.kernel.sysctl."net.core.rmem_max" = 8388608;

      services.collectdproxy.statshost.enable = true;
      services.collectdproxy.statshost.send_to =
        "${cfgStatsGlobal.hostName}:2003";

      # Global prometheus configuration
      environment.etc = builtins.listToAttrs
        (map
          (p: nameValuePair "current-config/statshost-relay-${p.location}.json"  {
            text = builtins.toJSON [
              { targets = (map
                (s: "${s.node}:9126")
                (filter
                  (s: s.service == "statshost-collector" && s.location == p.location)
                  config.flyingcircus.enc_service_clients));
              }];
          })
        relayLocationProxies);

      # Since influx is also running on the machine, split memory between the
      # two. Once Influx is gone, this seeting allso needs to go.
      flyingcircus.roles.statshost.prometheusHeapMemoryPercentage = 40;

    })

    (mkIf (cfgStatsRG.enable || cfgProxyRG.enable) {
      environment.etc."local/statshost/scrape-rg.json".text = builtins.toJSON [{
        targets = builtins.sort builtins.lessThan (lib.unique
          (map
            (host: "${host.name}.fcio.net:9126")
            config.flyingcircus.enc_addresses.srv));
      }];
    })

    (mkIf cfgStatsRG.enable {
      environment.etc = {
        "local/statshost/metric-relabel.yaml.example".text = ''
          - source_labels: [ "__name__" ]
            regex: "re.*expr"
            action: drop
          - source_labels: [ "__name__" ]
            regex: "old_(.*)"
            replacement: "new_''${1}"
        '';
        "local/statshost/relays.json.example".text = ''
          [
            {
              "job_name": "otherproject",
              "proxy_url": "http://statshost-relay-otherproject.fcio.net:9090"
            }
          ]
        '';
        "local/statshost/README.txt".text =
          import ./README.nix { inherit config; };
      };

      # Update relayed nodes.
      systemd.services.fc-prometheus-update-relayed-nodes = (mkIf (relayRGNodes != []) {
        description = "Update prometheus proxy relayed nodes.";
        restartIfChanged = false;
        after = [ "network.target" ];
        wantedBy = [ "prometheus.service" ];
        serviceConfig = {
          User = "root";
          Type = "oneshot";
        };
        path = [ pkgs.curl pkgs.coreutils ];
        script = concatStringsSep "\n" (map
          (relayNode: ''
            curl -s -o /var/cache/statshost-relay-${relayNode.job_name}.json \
              ${relayNode.proxy_url}/scrapeconfig.json
          '')
          relayRGNodes);
      });

      systemd.timers.fc-prometheus-update-relayed-nodes = (mkIf (relayRGNodes != []) {
        description = "Timer for updating relayed targets";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          Unit = "fc-prometheus-update-relayed-nodes";
          OnUnitActiveSec = "11m";
          # Not yet supported by our systemd version.
          # RandomSec = "3m";
        };
      });
    })

    # An actual statshost. Enable Prometheus.
    (mkIf (cfgStatsGlobal.enable || cfgStatsRG.enable) {

      services.prometheus.enable = true;
      services.prometheus.extraFlags = promFlags;
      services.prometheus.listenAddress = prometheusListenAddress;
      services.prometheus.scrapeConfigs = [
        { job_name = "prometheus";
          scrape_interval = "5s";
          static_configs = [{
            targets = [ prometheusListenAddress ];
            labels = {
              host = config.networking.hostName;
            };
          }];
        }
        rec {
          job_name = config.flyingcircus.enc.parameters.resource_group;
          scrape_interval = "15s";
          # We use a file sd here. Static config would restart prometheus for
          # each change. This way prometheus picks up the change automatically
          # and without restart.
          file_sd_configs = [{
            files = [ "/etc/local/statshost/scrape-*.json" ];
            refresh_interval = "10m";
          }];
          metric_relabel_configs =
            prometheusMetricRelabel ++
            (relabelConfiguration
              "/etc/local/statshost/metric-relabel.${job_name}.yaml");
        }
        {
          job_name = "fedrate";
          scrape_interval = "15s";
          metrics_path = "/federate";
          honor_labels = true;
          params = {
            "match[]" = [
              "{job=~\"static|prometheus\"}"
            ];
          };
          file_sd_configs = [{
            files = [ "/etc/local/statshost/federate-*.json" ];
            refresh_interval = "10m";
          }];
          metric_relabel_configs = prometheusMetricRelabel;
        }

      ]
      ++ relayRGConfig
      ++ relayLocationConfig;

      system.activationScripts.statshost = {
        text = "install -d -g service -m 2775 /etc/local/statshost";
        deps = [];
      };

    flyingcircus.services.sensu-client.checks = {
        prometheus = {
          notification = "Prometheus http port alive";
          command = ''
            check_http -H ${config.networking.hostName} -p 9090 -u /metrics
          '';
        };
      };

    })

    # Grafana
    (mkIf (cfgStatsGlobal.enable || cfgStatsRG.enable) {
      services.grafana = {
        enable = true;
        port = 3001;
        addr = "127.0.0.1";
        rootUrl = "http://${cfgStatsGlobal.hostName}/grafana";
        extraOptions = {
          AUTH_LDAP_ENABLED = "true";
          AUTH_LDAP_CONFIG_FILE = toString grafanaLdapConfig;
          LOG_LEVEL = "info";
          DASHBOARDS_JSON_ENABLED = "true";
          DASHBOARDS_JSON_PATH = "${grafanaJsonDashboardPath}";
        };
      };

      flyingcircus.roles.nginx.enable = true;
      flyingcircus.roles.nginx.httpConfig =
        let
          httpHost = cfgStatsGlobal.hostName;
          common = ''
            server_name ${httpHost};

            location /.well-known {
              root /tmp/letsencrypt;
            }

            location = / {
                rewrite ^ /grafana/ redirect;
            }

            location / {
                # Allow access to prometheus
                auth_basic "FCIO user";
                auth_basic_user_file "/etc/local/nginx/htpasswd_fcio_users";
                proxy_pass http://${prometheusListenAddress};
            }

            location /grafana/ {
                proxy_pass http://127.0.0.1:3001/;
            }

          '';
        in
        if cfgStatsGlobal.useSSL then ''
          server {
              ${fclib.nginxListenOn config "ethfe" 80}
              server_name ${httpHost};

              location / {
                rewrite ^ https://$server_name$request_uri redirect;
              }
          }

          server {
              ${fclib.nginxListenOn config "ethfe" "443 ssl http2"}
              ${common}

              ssl_certificate ${/etc/local/nginx/stats.crt};
              ssl_certificate_key ${/etc/local/nginx/stats.key};
              # add_header Strict-Transport-Security "max-age=31536000";
          }
        ''
        else
        ''
          server {
              ${fclib.nginxListenOn config "ethfe" 80}
              ${common}
          }
        '';

      networking.firewall.allowedTCPPorts = [ 2004 ];
      networking.firewall.allowedUDPPorts = [ 2003 ];

      # Provide FC dashboards, and update them automatically.
      systemd.services.fc-grafana-load-dashboards = {
        description = "Update grafana dashboards.";
        restartIfChanged = false;
        after = [ "network.target" "grafana.service" ];
        wantedBy = [ "grafana.service" ];
        serviceConfig = {
          User = "grafana";
          Type = "oneshot";
        };
        path = [ pkgs.git pkgs.coreutils ];
        environment = {
          SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
        };
        script = ''
          if [ -d ${grafanaJsonDashboardPath} -a -d ${grafanaJsonDashboardPath}/.git ];
          then
            cd ${grafanaJsonDashboardPath}
            git pull
          else
            rm -rf ${grafanaJsonDashboardPath}
            git clone ${cfgStatsGlobal.dashboardsRepository} ${grafanaJsonDashboardPath}
          fi
        '';
      };

      systemd.timers.fc-grafana-load-dashboards = {
        description = "Timer for updating the grafana dashboards";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          Unit = "fc-grafana-load-dashboards.service";
          OnUnitActiveSec = "1h";
          # Not yet supported by our systemd version.
          # RandomSec = "3m";
        };
      };

    })

    # collectd proxy
    (mkIf (cfgProxyGlobal.enable && statshostService != null) {
      services.collectdproxy.location.enable = true;
      services.collectdproxy.location.statshost = cfgStatsGlobal.hostName;
      services.collectdproxy.location.listen_addr = config.networking.hostName;
      networking.firewall.allowedUDPPorts = [ 2003 ];
    })
  ];
}

# vim: set sw=2 et:
