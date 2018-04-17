{ pkgs, fetchurl, fetchFromGitHub }:

let
  pname = "vulnix";
  version = "b831569";
  python = import ./requirements.nix { inherit pkgs; };
  src = fetchFromGitHub {
    owner = "flyingcircusio";
    repo = "vulnix";
    rev = "${version}";
    sha256 = "17jxb5sif3arsfwvb5l98gcgyd94wk7gzs0zrgbr4l9jjf6skx01";
  };

in
python.mkDerivation {
  inherit version src;
  name = "${pname}-${version}";

  propagatedBuildInputs = [
    pkgs.nix
    python.packages."click"
    python.packages."colorama"
    python.packages."lxml"
    python.packages."PyYAML"
    python.packages."toml"
    python.packages."requests"
    python.packages."ZODB"
  ];

  doCheck = false;

  meta = {
    description = "NixOS vulnerability scanner";
    homepage = https://github.com/flyingcircusio/vulnix;
    license = pkgs.lib.licenses.bsd2;
  };
}
