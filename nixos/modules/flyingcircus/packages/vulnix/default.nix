{ pkgs, fetchurl, python3Packages }:

let
  pname = "vulnix";
  version = "1.4.0";
  python = import ./requirements.nix { inherit pkgs; };
  src = python3Packages.fetchPypi {
    inherit pname version;
    sha256 = "19kfqxlrigrgwn74x06m70ar2fhyhic5kfmdanjwjcbaxblha3l8";
  };

in
python.mkDerivation {
  inherit version src;
  name = "${pname}-${version}";

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
