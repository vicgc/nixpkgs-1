# This test has been broken but still signaled "green" earlier on.
# I have disabled it for now.
import ../../../tests/make-test.nix ({ pkgs, lib, ... }:
{
  name = "rabbitmq";

  nodes = {
    master =
      { pkgs, config, ... }:
      {
        imports = [
          ./setup.nix
          ../static/default.nix
          ../services/default.nix
          ../platform/default.nix
        ];

        services.rabbitmq.enable = true;

      };
  };

  testScript = ''
    startAll;

    $master->waitForUnit("rabbitmq");
    $master->succeed("HOME=/var/lib/rabbitmq rabbitmqctl status");
  '';
})
