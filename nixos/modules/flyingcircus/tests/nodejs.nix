{ system, hydraJob }:

let
  testFactory = version: vname: (hydraJob (nodejsTest version vname { inherit system; }));

  nodejsTest = version: vname:
    import ../../../tests/make-test.nix ({...}:
    {
      name = "nodejs-${version}";

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

          nixpkgs.config.packageOverrides = pkgs: {
            nodejs = pkgs.${version};
          };
        };
      };

      testScript = ''
        startAll;

        $master->succeed('node -e \'console.log("ok")\' ');
        $master->succeed('node --version | grep ${vname}');
      '';
    });
in
{
  nodejs_4 = testFactory "nodejs4" "v4.";
  nodejs_6 = testFactory "nodejs6" "v6.";
  nodejs_7 = testFactory "nodejs7" "v7.";
}

