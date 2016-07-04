{ pkgs ? import <nixpkgs> { }
, python3Packages ? pkgs.python3Packages
, fcmaintenance ? import ../fcmaintenance { inherit pkgs; }
, fcutil ? import ../fcutil { inherit pkgs; }
, nix
}:

python3Packages.buildPythonPackage rec {
  name = "fc-manage-${version}";
  version = "1.0";
  namePrefix = "";
  dontStrip = true;
  src = ./.;

  buildInputs = with pkgs.python3Packages; [ covCore pytest pytestcov ];
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
  checkPhase = ''
    export PYTHONPATH="${src}/src:$PYTHONPATH"
    py.test
  '';
}
