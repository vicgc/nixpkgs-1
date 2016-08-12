{ fetchurl, pkgs ? import <nixpkgs> {} }:

let
  python = import ./requirements.nix { inherit pkgs; };
  version = "1.1.1dev0.dev0";
in python.mkDerivation rec {
  name = "vulnix-${version}";
  src = fetchurl {
      url = "https://hydra.flyingcircus.io/build/5541/download/1/${name}.tar.gz";
      sha256 = "1ngwpwqv2j5kj8cxrdbxgsm3d0nxrjn74ql7rc4fj5lszdwlc642";
    };
  # TODO: improve on internal and external dependencies
  buildInputs = [
    python.pkgs.flake8
    python.pkgs.pytest
    python.pkgs."pytest-cache"
    python.pkgs."pytest-capturelog"
    python.pkgs."pytest-codecheckers"
    python.pkgs."pytest-cov"
    python.pkgs."pytest-timeout"
  ];
   propagatedBuildInputs = [
    python.pkgs."click"
    python.pkgs."colorama"
    python.pkgs."PyYAML"
    python.pkgs."requests"
  ];
  doCheck = false;

  meta = with pkgs.lib; {
    homepage = https://github.com/flyingcircusio/vulnix;
    description = "vulnerability scanner for nix";
  };
}
