{ pkgs, fetchurl }:

let
  python = import ./requirements.nix { inherit pkgs; };
  version = "1.2.2";
  src = fetchurl {
    url = "https://pypi.python.org/packages/90/c9/ebef9243334a99edb8598061efae0f00d7a199b01bea574a84e31e06236d/vulnix-${version}.tar.gz";
    sha256 = "1ia9plziwach0bxnlcd33q30kcsf8sv0nf2jc78gsmrqnxjabr12";
  };

in
python.mkDerivation {
  inherit version src;
  name = "vulnix-${version}";

  buildInputs = [
    python.packages."flake8"
    python.packages."pytest"
    python.packages."pytest-capturelog"
    python.packages."pytest-codecheckers"
    python.packages."pytest-cov"
    python.packages."pytest-timeout"
  ];

  propagatedBuildInputs = [
    pkgs.nix
    python.packages."click"
    python.packages."colorama"
    python.packages."lxml"
    python.packages."PyYAML"
    python.packages."requests"
    python.packages."ZODB"
  ];

  checkPhase = ''
    export PYTHONPATH=src:$PYTHONPATH
    py.test
  '';

  meta = {
    description = "NixOS vulnerability scanner";
    homepage = https://github.com/flyingcircusio/vulnix;
    license = pkgs.lib.licenses.bsd2;
  };
}
