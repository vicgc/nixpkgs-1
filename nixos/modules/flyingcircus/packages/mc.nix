{ pkgs ? import <nixpkgs> { }
, python34Packages ? pkgs.python34Packages
, stdenv ? pkgs.stdenv
, lib ? pkgs.lib
, fetchurl ? pkgs.fetchurl
}:

stdenv.mkDerivation rec {
  name = "mc-${version}";
  version = "4.8.17";

  src = fetchurl {
    url = "http://ftp.midnight-commander.org/mc-${version}.tar.bz2";
    sha256 = "66d0cb37baaed8ef930f8ad25a634adad4f264eb61820893920ac87b9dfb783b";
  };

  propagatedBuildInputs = [
    pkgs.glib
  ];

  buildInputs = [
    pkgs.pkgconfig
    pkgs.slang
    pkgs.perl
   ];

  enableParallelBuilding = true;
  configureFlagsArray = [
    ];
  meta = {
    homepage = http://www.midnight-commander.org;
    description = "GNU Midnight Commander is a visual file manager.";
  };
}
