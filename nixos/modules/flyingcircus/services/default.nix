{ ... }:

{
  imports =
    [
     ./agent.nix
     ./clamav.nix
     ./collectdproxy.nix
     ./coturn.nix
     ./grafana.nix
     ./graylog.nix
     ./influxdb011.nix
     ./kibana.nix
     ./percona.nix
     ./powerdns.nix
     ./prometheus
     ./rabbitmq.nix
     ./rsyslog.nix
     ./sensu/api.nix
     ./sensu/client.nix
     ./sensu/server.nix
     ./sensu/uchiwa.nix
     ./strongswan.nix
     ./telegraf.nix
    ];
}
