{ pkgs, libyaml, python34Packages }:

let
  py = python34Packages;

in
  py.buildPythonPackage rec {
    name = "fc-sensuplugins-${version}";
    version = "1.0";
    namePrefix = "";
    src = ./.;
    dontStrip = true;
    propagatedBuildInputs = [
      libyaml
      py.nagiosplugin
      py.psutil
      py.pyyaml
      py.requests2
    ];
  }
