import ../../../tests/make-test.nix ({ ... }:
{
  name = "kibana";

  nodes = {
    master =
      { pkgs, config, ... }:
      {

        imports = [
          ./setup.nix
          ../static/default.nix
          ../roles/default.nix
          ../services/default.nix
          ../platform/default.nix
        ];

        virtualisation.memorySize = 2048;
        flyingcircus.roles.elasticsearch.enable = true;
        flyingcircus.roles.kibana.enable = true;
        flyingcircus.roles.kibana.elasticSearchUrl = "http://localhost:9200/";

      };
  };

  testScript = ''
    startAll;

    $master->waitForUnit("elasticsearch");
    $master->waitForUnit("kibana");

    # cluster healthy?
    $master->succeed(<<EOF
      for count in {0..60}; do
        curl -s "localhost:5601/api/status" |  grep -q '"state":"green' && exit
        echo "Checking"
        sleep 1
      done
      echo "Failed"
      exit 1
    EOF
    );
  '';
})
