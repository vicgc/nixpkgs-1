{ pkgs ? import <nixpkgs> { }
, python34Packages ? pkgs.python34Packages
, fcutil ? import ../fcutil { inherit pkgs python34Packages; }
, fcmaintenance ? import ../fcmaintenance { inherit pkgs python34Packages; }
}:

with python34Packages;

buildPythonPackage rec {
  name = "fc-manage-${version}";
  version = "1.0";
  namePrefix = "";
  dontStrip = true;
  src = ./.;

  buildInputs = [ pytest ];

  propagatedBuildInputs = with pkgs;
    [ dmidecode
      fcmaintenance
      fcutil
      gptfdisk
      lvm2
      multipath_tools
      nix
      utillinux
      xfsprogs
    ];
}
