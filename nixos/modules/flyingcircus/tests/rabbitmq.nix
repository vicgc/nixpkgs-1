# This test has been broken but still signaled "green" earlier on.
# I have disabled it for now.
import ../../../tests/make-test.nix ({ ... }:
{
  name = "rabbitmq";

  nodes = {
    vm =
      { pkgs, config, ... }:
      {
        imports = [
          ./setup.nix
          ../static
          ../services
          ../platform
        ];

        services.rabbitmq.enable = true;
      };
  };

  testScript = ''
    startAll;

    $vm->waitForUnit("rabbitmq");
    $vm->succeed(<<_EOT_);
    export HOME=/var/lib/rabbitmq
    rabbitmqctl status | tee /dev/stderr | egrep 'uptime,[1-9]'
    _EOT_
  '';
})
