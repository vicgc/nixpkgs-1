import ../../../../tests/make-test.nix ({ ... }:
{
  name = "mongodb";

  nodes = {
    vm =
      { pkgs, config, ... }:
      {
        imports = [
          ../setup.nix
          ../../static
          ../../roles
          ../../services
          ../../platform
        ];

        virtualisation.memorySize = 2048;
        flyingcircus.roles.mongodb32.enable = true;
      };
    };

    testScript = ''
      startAll;
      $vm->waitForUnit("mongodb");

      $vm->succeed(<<'__SHELL__');
      set -e

      mongo < ${./restaurants.js} | egrep -10 '"nInserted" : 3'

      mongo <<__MONGO__ | egrep -10 'Dj Reynolds Pub And Restaurant'
      use test;
      db.restaurants.find( { "borough": "Manhattan" } );
      __MONGO__
      __SHELL__

    '';
})
