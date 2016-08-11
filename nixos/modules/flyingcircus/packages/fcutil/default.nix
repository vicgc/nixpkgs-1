{ pkgs ? import <nixpkgs> { }
, python34Packages ? pkgs.python34Packages
}:

python34Packages.buildPythonPackage rec {
  name = "fc-util-${version}";
  version = "1.0";
  src = ./.;
  doCheck = false;
}
