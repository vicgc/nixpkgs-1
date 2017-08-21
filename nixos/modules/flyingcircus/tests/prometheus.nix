import ../../../tests/make-test.nix ({lib, pkgs, ... }:
{
  machine =
    { config, ... }:
    {
      imports = [
        ../platform
        ../services/agent.nix
        ../services/prometheus
        ../services/sensu/client.nix
        ../static
        ./setup.nix
      ];

      config.services.prometheus.enable = true;
    };
  testScript =
    ''
      $machine->waitForUnit("prometheus.service");
      $machine->sleep(5);
      $machine->succeed("curl 'localhost:9090/metrics' | grep go_goroutines");
    '';
})
