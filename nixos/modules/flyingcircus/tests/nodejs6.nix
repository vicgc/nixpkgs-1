import ../../../tests/make-test.nix ({ ... }:
{
  name = "nodejs6";

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

        virtualisation.memorySize = 1024;
        environment.systemPackages = [
          pkgs.nodejs6
        ];
      };
  };

  testScript = ''
    startAll;

    $master->succeed('node -e \'console.log("ok")\' ');
  '';
})
