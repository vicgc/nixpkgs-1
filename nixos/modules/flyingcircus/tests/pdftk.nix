import ../../../tests/make-test.nix ({ ... }:
{
  name = "pdftk";
  # This test does *not* really test pdftk and causes the
  # dependencies to be built.

  nodes = {
    master =
      { pkgs, config, ... }:
      {

        virtualisation.memorySize = 512;
        environment.systemPackages = with pkgs; [
            pdftk
        ];
      };
  };

  testScript = ''
    startAll;
  '';
})
