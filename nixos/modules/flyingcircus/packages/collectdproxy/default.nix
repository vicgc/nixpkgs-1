{ pkgs
, python34Packages
}:

let
  py = python34Packages;

in
py.buildPythonPackage rec {
  name = "collectdproxy-${version}";
  version = "1.0";
  namePrefix = "";
  dontStrip = true;
  src = ./.;

  buildInputs = [
    py.pytest
  ];

  propagatedBuildInputs = [
  ];

}
