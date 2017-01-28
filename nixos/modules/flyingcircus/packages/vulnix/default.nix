{ pkgs, stdenv, unzip, fetchurl }:

let
  vulnixSrc = stdenv.mkDerivation rec {
    name = "vulnix-src-${version}";
    version = "1.2.2";
    src = fetchurl {
      url = "https://pypi.python.org/packages/90/c9/ebef9243334a99edb8598061efae0f00d7a199b01bea574a84e31e06236d/vulnix-${version}.tar.gz";
      sha256 = "1ia9plziwach0bxnlcd33q30kcsf8sv0nf2jc78gsmrqnxjabr12";
    };
    buildInputs = [ unzip ];
    dontBuild = true;
    preferLocalBuild = true;
    installPhase = "mkdir $out; cp -r * $out";
    dontStrip = true;
    dontPatchELF = true;
  };

in
# the archive contains a usable default.nix - so why not use it?
import "${vulnixSrc}" { inherit pkgs; }
