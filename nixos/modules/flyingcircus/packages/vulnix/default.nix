{ pkgs, fetchurl }:

let
  python = import ./requirements.nix { inherit pkgs; };
  version = "1.3.0";
  src = fetchurl {
    url = https://pypi.python.org/packages/d1/90/c91e8f3607d01e267f1fd85872c9410aa230856ebc1c175fad1aaf20095c/vulnix-1.3.0.tar.gz;
    sha256 = "18l5va4jlfsrghz4dknqa8yw6chr74vhhld3ziv034vm5aganbyk";
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
    export PYTHONPATH=build/lib:$PYTHONPATH
    py.test build/lib/vulnix
  '';

  meta = {
    description = "NixOS vulnerability scanner";
    homepage = https://github.com/flyingcircusio/vulnix;
    license = pkgs.lib.licenses.bsd2;
  };
}
