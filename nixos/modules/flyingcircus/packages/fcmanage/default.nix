{ pkgs, python3Packages, nix }:

python3Packages.buildPythonPackage rec {
  name = "fc-manage-${version}";
  version = "1.0";
  namePrefix = "";
  dontStrip = true;
  src = ./.;

  buildInputs = with pkgs.python3Packages; [ covCore pytest pytestcov ];
  propagatedBuildInputs = with pkgs;
    [ fcmaintenance
      fcutil
      gptfdisk
      lvm2
      multipath_tools
      nix
      utillinux
      xfsprogs
    ];
  checkPhase = ''
    runHook preCheck

    ${python}/bin/py.test

    runHook postCheck
}
