{ pkgs ? import <nixpkgs> { }
, python34Packages ? pkgs.python34Packages
, fcutil ? import ../fcutil { inherit pkgs python34Packages; }
, pypkg ? import ../pypkg.nix { inherit pkgs python34Packages; }
}:

with python34Packages;

let

in
  buildPythonPackage rec {
    name = "fc-maintenance-${version}";
    version = "2.0";
    namePrefix = "";
    src = ./.;
    buildInputs = [
      pypkg.freezegun
      pypkg.pytestcatchlog
      pytest
    ];
    propagatedBuildInputs = [
      fcutil
      iso8601
      pytz
      pyyaml
      shortuuid
    ];
    dontStrip = true;
  }
