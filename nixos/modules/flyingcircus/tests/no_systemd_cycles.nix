import ../../../tests/make-test.nix ({ pkgs, ... }:

{
  name = "login";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ theuni ];
  };

  nodes = {
    machine =
      { pkgs, config, ... }:
      {
        imports = [
          ./setup.nix
          ../static/default.nix
          ../services/default.nix
          ../platform/default.nix
        ];

      };
  };

  testScript =
    ''
      $machine->waitForUnit('multi-user.target');
      $machine->waitUntilSucceeds("pgrep -f 'agetty.*tty1'");

      $machine->succeed("journalctl -b | egrep \"systemd.*cycle\" && exit 1 || exit 0");
    '';

})
