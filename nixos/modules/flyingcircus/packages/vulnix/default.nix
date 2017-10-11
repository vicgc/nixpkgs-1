{ pkgs, fetchurl }:

let
  python = import ./requirements.nix { inherit pkgs; };
  version = "1.3.2";
  src = fetchurl {
    url = https://pypi.python.org/packages/a9/66/f3e435c6d74f61afc944e29630a73e10b11e2a7e4f4ecd3e117518823127/vulnix-1.3.2.tar.gz;
    sha256 = "19mzxbqb5kjas7yk6hc99sb97sg10bkh1m55d8hn194ra3sryxmi";
  };

in
python.mkDerivation {
  inherit version src;
  name = "vulnix-${version}";

  buildInputs = [
    python.packages."flake8"
    python.packages."pytest"
    python.packages."pytest-catchlog"
    python.packages."pytest-codecheckers"
    python.packages."pytest-cov"
    python.packages."pytest-timeout"
    python.packages."urllib3"
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
    py.test src/vulnix
  '';

  meta = {
    description = "NixOS vulnerability scanner";
    homepage = https://github.com/flyingcircusio/vulnix;
    license = pkgs.lib.licenses.bsd2;
  };
}
