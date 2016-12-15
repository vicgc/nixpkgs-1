{ pkgs
, dmidecode
, fcmaintenance
, gptfdisk
, lvm2
, multipath_tools
, nix
, python34Packages
, utillinux
, xfsprogs }:

let
  py = python34Packages;
in
py.buildPythonPackage rec {
  name = "fc-manage-${version}";
  version = "1.0";
  namePrefix = "";
  dontStrip = true;
  src = ./.;

  buildInputs = [
    py.mock
    py.pytest
  ];

  propagatedBuildInputs = [
    dmidecode
    fcmaintenance
    gptfdisk
    lvm2
    multipath_tools
    nix
    py.fcutil
    py.requests2
    utillinux
    xfsprogs
  ];
}
