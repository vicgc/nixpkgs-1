import ../../../tests/make-test.nix ({ pkgs, lib, ... }:
{
  name = "elasticsearch";

  nodes = {
    master =
      { pkgs, config, ... }:
      {

        virtualisation.memorySize = 2048;

        imports = [
          ./setup.nix
          ../static/default.nix
          ../roles/default.nix
          ../services/default.nix
          ../platform/default.nix
        ];

        flyingcircus.roles.elasticsearch.enable = true;

      };
  };

  testScript = ''
    startAll;

    $master->waitForUnit("elasticsearch");

  '';
})
