{ pkgs, fetchurl }:

let
  python = import ./requirements.nix { inherit pkgs; };
  version = "1.3.3";
  src = fetchurl {
    url = https://pypi.python.org/packages/b8/11/16478573b2f341b84fb6357785511d33551f4515ef6c3661a79cf04da786/vulnix-1.3.3.tar.gz;
    sha256 = "1fhlgvp78np8i2wab6q6ypgl1bd4d1vlvip4j51fs8226qpyd7y2";
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
