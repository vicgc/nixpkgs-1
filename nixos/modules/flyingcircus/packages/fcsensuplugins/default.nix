{ pkgs ? import <nixpkgs> { }
, python34Packages ? pkgs.python34Packages
, nagiosplugin ? import ../nagiosplugin.nix { pkgs = pkgs; }
}:

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
      nagiosplugin
      py.psutil
      py.pyyaml
      pkgs.libyaml
    ];

    postInstall = ''
      mkdir -p "$out/share"
      cp ./fc/sensuplugins/check_logfiles.yaml "$out/share/"
    '';
  }
