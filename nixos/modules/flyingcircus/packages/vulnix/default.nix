{ pkgs }:

let
  python = import ./requirements.nix { inherit pkgs; };
in
python.mkDerivation rec {
  name = "vulnix-1.2";

  src = pkgs.fetchurl {
    url = "https://pypi.python.org/packages/06/4a/2e599efe40ca43e38bbef31be38fcc0469ffee00ebd06507e59fbd90f39e/vulnix-1.2.tar.gz";
    sha256 = "0gjsr0hmcpmmvmbbawa5zibc4dhzrsaw9srlwzipvnimiq8sy755";
  };

  propagatedBuildInputs = [
    pkgs.nix
    python.packages."click"
    python.packages."colorama"
    python.packages."PyYAML"
    python.packages."requests"
    python.packages."lxml"
    python.packages."ZODB"
  ];

  dontStrip = true;

  meta = {
    description = "NixOS vulnerability scanner";
    homepage = https://github.com/flyingcircusio/vulnix;
    license = pkgs.lib.licenses.bsd2;
  };
}
