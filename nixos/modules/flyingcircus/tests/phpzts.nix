# Some extensions (like redis) require ZTS in PHP. We don't know if it's wise
# to enable it globally. So we allow it to be customized via
# `.nixpkgs/config.nix`. Building PHP takes quite a while. This test causes
# a pre-built PHP with ZTS enabled as a side-effect.
import ../../../tests/make-test.nix ({ lib, pkgs, ... }:
{
  name = "phpzts";
  machine =
    { config, ... }:
    {
      imports = [
        ./setup.nix
        ../static
        ../roles
        ../services
        ../platform
      ];

    };
  testScript =
    let
      php56 = (pkgs.php56.override { config.php.zts = true; });
      php70 = (pkgs.php70.override { config.php.zts = true; });
      php77 = (pkgs.php77.override { config.php.zts = true; });
    in
    ''
      startAll;
      $machine->succeed("${php56}/bin/php -i | grep no-debug-zts >/dev/console");
      $machine->succeed("${php70}/bin/php -i | grep no-debug-zts >/dev/console");
      $machine->succeed("${php71}/bin/php -i | grep no-debug-zts >/dev/console");
    '';
})
