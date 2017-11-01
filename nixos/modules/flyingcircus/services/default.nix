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
     ./telegraf.nix
    ];

  # get rid of sadc logs as we have a better metrics infrastructure now
  # remove this after 2018-02-01
  system.activationScripts.sysstat = {
    text = "rm -rf /var/log/sa";
    deps = [];
  };
}
