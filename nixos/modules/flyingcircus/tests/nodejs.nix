{ system, hydraJob }:

let
  testFactory = version: (hydraJob (nodejsTest version { inherit system; }));

  nodejsTest = version:
    import ../../../tests/make-test.nix ({...}:
    {
      name = "${version}";
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
            pkgs.${version}
          ];
        };
      };

      testScript = ''
        startAll;

        $master->succeed('node -e \'console.log("ok")\' ');
      '';
    });
in
{
  nodejs_4 = testFactory "nodejs4";
  nodejs_6 = testFactory "nodejs6";
  nodejs_7 = testFactory "nodejs7";
}

