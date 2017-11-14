import ../../../tests/make-test.nix ({ pkgs, ... }:
{
  name = "docsplit";

  nodes = {
    srv1 =
      { pkgs, config, ... }:
      {
        imports = [
          ./setup.nix
          ../static
          ../roles
          ../services
          ../platform
        ];

      };
  };

  testScript = ''
    startAll;
    $srv1->succeed(<<'__SHELL__');
    ${pkgs.docsplit}/bin/docsplit --help
    __SHELL__
  '';
})
