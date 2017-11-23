import ../../../tests/make-test.nix ({ pkgs, ... }:

# Checks that systemd does not detect any circular service dependencies on boot.
{
  name = "systemd_cycles";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ theuni ];
  };

  nodes = {
    cycles =
      { ... }:
      {
        imports = [
          ./setup.nix
          ../static
          ../services
          ../platform
        ];
      };
  };

  testScript = ''
    $cycles->waitForUnit('multi-user.target');
    $cycles->waitUntilSucceeds('pgrep -f "agetty.*tty1"');
    $cycles->fail('journalctl -b | egrep "systemd.*cycle"');
  '';
})
