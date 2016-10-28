{ pkgs }:

let
  python = import ./requirements.nix { inherit pkgs; };
in
python.mkDerivation rec {
  name = "vulnix-1.1.5";

  src = pkgs.fetchurl {
    url = "https://pypi.python.org/packages/de/1e/66ce22166bfcf60853511ba2d0b663ece96dd5df34a5077d176391db927d/${name}.tar.gz";
    sha256 = "0h9jraga7gd9gbkndb41ilm7chkdp5xvjf2vfg1c5alsl95rswlv";
  };

  propagatedBuildInputs = [
    pkgs.nix
    python.packages."click"
    python.packages."colorama"
    python.packages."PyYAML"
    python.packages."requests"
  ];

  dontStrip = true;

  meta = {
    description = "NixOS vulnerability scanner";
    homepage = https://github.com/flyingcircusio/vulnix;
    license = pkgs.lib.licenses.bsd2;
  };
}
