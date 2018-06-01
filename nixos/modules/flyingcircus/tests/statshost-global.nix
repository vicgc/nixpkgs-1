import ../../../tests/make-test.nix ({lib, pkgs, ... }:
{
  name = "statshost-global";
  machine =
    { config, ... }:
    {
      imports = [
        ./setup.nix
        ../platform
        ../services
        ../static
        ../roles
        ../infrastructure/fcio/telegraf.nix
      ];

      flyingcircus.roles.statshost.enable = true;

      flyingcircus.enc.parameters.resource_group = "test";
      flyingcircus.enc.parameters.interfaces.srv = {
        bridged = false;
        mac = "52:54:00:12:34:56";
        networks = {
          "192.168.101.0/24" = [ "192.168.101.1" ];
          "2001:db8:f030:1c3::/64" = [ "2001:db8:f030:1c3::1" ];
        };
        gateways = {};
      };
      flyingcircus.enc_addresses.srv = [
        { name = "myself";
          ip = "192.168.101.1"; }
      ];
      networking.extraHosts = ''
        192.168.101.1 myself.fcio.net myself
      '';

      # Add a scrape target for our test node. Globally nodes are only scraped
      # via relay/proxy, but we don't want/need to set this up here.
      environment.etc."local/statshost/scrape-test.json".text =
        builtins.toJSON [ { targets = [ "myself.fcio.net:9126" ]; } ];
    };

  testScript =
    ''
      $machine->waitForUnit("prometheus.service");
      $machine->waitForUnit("telegraf.service");
      $machine->waitForFile("/run/telegraf/influx.sock");

      # Job for RG test created and up?
      $machine->waitUntilSucceeds(<<'EOF');
        curl -s http://192.168.101.1:9090/api/v1/targets | \
          jq -e \
          '.data.activeTargets[] |
            select(.health == "up" and .labels.job == "test")'
      EOF

      # Index custom metric, and expect it *not* to be found in prometheus
      # The extended sleep is necessary to wait for the scape cycle. Still it's
      # a bit fuzzy.

      $machine->succeed(<<'EOF');
        echo my_custom_metric value=42 | \
          ${pkgs.socat}/bin/socat - UNIX-CONNECT:/run/telegraf/influx.sock
      EOF

      $machine->sleep(16);
      $machine->fail(<<'EOF');
        curl -s \
            http://192.168.101.1:9090/api/v1/query?query='my_custom_metric' | \
         jq -e '.data.result[].value[1] == "42"'
      EOF
    '';
})

