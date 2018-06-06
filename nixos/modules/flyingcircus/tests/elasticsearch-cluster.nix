import ../../../tests/make-test.nix ({
rolename ? "elasticsearch2"
, ... }:
rec {
  name = rolename;

  esConfig = id: {
    clusterName = "testcluster";
    esNodes = [ "192.168.101.1" "192.168.101.2" ];
    thisNode = "192.168.101.${toString id}";
  };

  vlan = 2;

  esNode = id:
    { pkgs, config, lib, ...}:
    {

      imports = [
        ./setup.nix
        ../static
        ../roles
        ../services
        ../platform
      ];

      flyingcircus.enc.parameters.interfaces.srv = {
        bridged = false;
        mac = "52:54:00:12:0${toString vlan}:0${toString id}";
        networks = {
          "192.168.101.0/24" = [ "192.168.101.${toString id}" ];
          "2001:db8:f030:1c3::/64" = [ "2001:db8:f030:1c3::${toString id}" ];
        };
        gateways = {};
      };

      virtualisation.memorySize = 2048;
      virtualisation.vlans = [ vlan ];

      flyingcircus.roles.${rolename}.enable = true;
      flyingcircus.roles.elasticsearch = esConfig id;
      networking.firewall.enable = false;
      networking.firewall.allowPing = true;
    };

  nodes = {
    node1 = esNode 1;
    node2 = esNode 2;
  };

  testScript = ''
    startAll;

    $node1->waitForUnit("elasticsearch");
    $node2->waitForUnit("elasticsearch");

    # cluster healthy?
    $node1->waitUntilSucceeds(
      'curl -s "192.168.101.1:9200/_cat/health?v" | logger -s 2>&1 | grep green');

    $node1->waitUntilSucceeds(<<'EOF');
      curl -s "192.168.101.1:9200/_cluster/health" | \
        jq -e ".number_of_nodes == 2"
    EOF

    $node1->succeed(<<'EOF');
      curl -X PUT "192.168.101.1:9200/customers" \
        -H 'Content-Type: application/json' -d'
        {
            "settings" : {
                "index" : {
                    "number_of_shards" : 1,
                    "number_of_replicas" : 1
                }
            }
        }'
      curl -s '192.168.101.1:9200/_cat/indices?v'
    EOF

    $node1->waitUntilSucceeds(
      'curl -s "192.168.101.1:9200/_cat/health?v" | logger -s 2>&1 | grep green');

    $node1->block();
    $node1->waitUntilSucceeds(
      'curl -s "192.168.101.1:9200/_cat/health?v" | grep yellow');

    $node1->sleep(120);

    # do the nodes find each other again?
    $node1->unblock();
    $node1->waitUntilSucceeds(
      'curl -s "192.168.101.1:9200/_cat/health?v" | grep green');
  '';
})
