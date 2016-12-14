# build fcmaintenance only for a specific Python version, so don't put it into
# python-packages.nix
{ pkgs, python34Packages }:

let
  py = python34Packages;
in
py.buildPythonPackage rec {
  name = "fc-maintenance-${version}";
  version = "2.0";
  namePrefix = "";
  src = ./.;
  buildInputs = [
    py.freezegun
    py.pytestcatchlog
    py.pytest
  ];
  propagatedBuildInputs = [
    py.fcutil
    py.iso8601
    py.pytz
    py.pyyaml
    py.shortuuid
  ];
  dontStrip = true;
}
