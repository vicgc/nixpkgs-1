{ callPackage, ... } @ args:

callPackage ./generic.nix (args // {
  version = "1.10.3";
  sha256 = "75020f1364cac459cb733c4e1caed2d00376e40ea05588fb8793076a4c69dd90";
})
