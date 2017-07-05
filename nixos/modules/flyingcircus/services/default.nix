{ ... }:

{
  imports =
    [
     ./collectdproxy.nix
     ./clamav.nix
     ./coturn.nix
     ./fcmanage.nix
     ./graylog.nix
     ./influxdb011.nix
     ./kibana.nix
     ./percona.nix
     ./powerdns.nix
     ./rabbitmq.nix
     ./rsyslog.nix
     ./sensu/api.nix
     ./sensu/client.nix
     ./sensu/server.nix
     ./sensu/uchiwa.nix
     ./sysstat.nix
    ];
}
