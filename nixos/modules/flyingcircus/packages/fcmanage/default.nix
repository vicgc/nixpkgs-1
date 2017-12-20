{ pkgs
, dmidecode
, fcmaintenance
, gptfdisk
, lvm2
, multipath_tools
, nix
, python34Packages
, utillinux
, xfsprogs
}:

let
  py = python34Packages;

in
py.buildPythonPackage rec {
  name = "fc-manage-${version}";
  version = "2.1";
  namePrefix = "";
  dontStrip = true;
  src = ./.;

  buildInputs = [
    py.mock
    py.pytest
    py.pytest-runner
  ];

  propagatedBuildInputs = [
    dmidecode
    fcmaintenance
    gptfdisk
    lvm2
    multipath_tools
    nix
    py.click
    py.fcutil
    py.requests2
    utillinux
    xfsprogs
  ];

}
