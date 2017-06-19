# statshost: an InfluxDB/Grafana server. Accepts incoming graphite traffic,
# stores it and renders graphs.
{ config, lib, pkgs, ... }:

with lib;

let
  fclib = import ../lib;

  cfgStatsGlobal = config.flyingcircus.roles.statshost;
  cfgStatsRG = config.flyingcircus.roles.statshost-master;
  cfgProxyGlobal = config.flyingcircus.roles.statshostproxy;
  cfgProxyRG = config.flyingcircus.roles.statshost-relay;

  prometheus = cfgStatsRG.enable || cfgProxyRG.enable;
  promFlags =
    if cfgStatsRG.enable
    then [
      "-storage.local.retention 1400h"
      "-storage.local.series-file-shrink-ratio 0.3"
      "-storage.local.memory-chunks 1048576"
    ]
    else [  # Proxy only
      "-storage.local.retention 24h"
      "-storage.local.series-file-shrink-ratio 0.1"
      "-storage.local.memory-chunks 1048576"  # Find out useful value.
    ];

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
    search_filter = "(uid=%s)"
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

    [[servers.group_mappings]]
    group_dn = "*"
    org_role = ""

  '';

in
{
  options = {

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
        default = "stats.flyingcircus.io";
        description = "HTTP host name for the stats frontend. Must be set.";
        example = "stats.example.com";
      };
    };

    flyingcircus.roles.statshostproxy = {
      enable = mkEnableOption "Enable stats proxy.";
    };


    flyingcircus.roles.statshost-master = {
      enable = mkEnableOption "Grafana/Prometheus stats host for one RG";
    };

    flyingcircus.roles.statshost-relay = {
      enable = mkEnableOption "Grafana/Prometheus stats relay";
    };

  };

  config = mkMerge [

    # Global stats host. Currently influxdb.
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
    })

    # RG-specific statshost. Prometheus
    (mkIf prometheus {

      environment.etc."local/statshost/scrape-rg.json".text = builtins.toJSON [{
        targets = builtins.sort builtins.lessThan (lib.unique
          (map
            (host: "${host.name}.fcio.net:9126")
            config.flyingcircus.enc_addresses.srv));
      }];

      services.prometheus.enable = true;
      services.prometheus.extraFlags = promFlags;
      services.prometheus.listenAddress =
        "${lib.head(fclib.listenAddressesQuotedV6 config "ethsrv")}:9090";
      services.prometheus.scrapeConfigs = [
        { job_name = "static";
          scrape_interval = "15s";
          file_sd_configs = [{
            files = ["/etc/local/statshost/scrape-*.json" ];
            refresh_interval = "10m";
          }];
        }
        { job_name = "fedrate";
          scrape_interval = "15s";
          metrics_path = "/federate";
          honor_labels = true;
          params = {
            "match[]" = [
              "{job=\"static\"}"
            ];
          };
          file_sd_configs = [{
            files = ["/etc/local/statshost/federate-*.json" ];
            refresh_interval = "10m";
          }];
        }
      ];

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
          LOG_LEVEL = "debug";
          LOG_FILTERS = "ldap:debug";
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

            location / {
                rewrite . /grafana/ redirect;
            }

            location /grafana/ {
                proxy_pass http://localhost:3001/;
            }

            location /grafana/public {
                alias ${config.services.grafana.staticRootPath};
            }
          '';
        in
        if cfgStatsGlobal.useSSL then ''
          server {
              listen *:80;
              listen [::]:80;
              server_name ${httpHost};
              rewrite . https://$server_name$request_uri redirect;
          }

          server {
              listen *:443 ssl;
              listen [::]:443 ssl;
              ${common}

              ssl_certificate ${/etc/local/nginx/stats.crt};
              ssl_certificate_key ${/etc/local/nginx/stats.key};
              # add_header Strict-Transport-Security "max-age=31536000";
          }
        ''
        else
        ''
          server {
              listen *:80;
              listen [::]:80;
              ${common}
          }
        '';

      networking.firewall.allowedTCPPorts = [ 80 443 2004 ];
      networking.firewall.allowedUDPPorts = [ 2003 ];

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
