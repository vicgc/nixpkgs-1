{ pkgs ? import <nixpkgs> {} }:

let
  python = import ./requirements.nix { inherit pkgs; };
  version = "1.1";
in python.mkDerivation {
  name = "vulnix-${version}";
  src = pkgs.fetchgit {
      url = "git://github.com/flyingcircusio/vulnix.git";
      rev = "dd75dd13c4f903a39daee49693fcce49ea3e0112";
      sha256 = "168pkav0x159mlr12nsfh4x097pp9qp6pbxmj5ivsn6vvac8xlrr";
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
