{ pkgs ? import <nixpkgs> { }
, stdenv ? pkgs.stdenv
, lib ? pkgs.lib
, fetchurl ? pkgs.fetchurl
}:

stdenv.mkDerivation rec {
  name = "proftpd-${version}";
  version = "1.3.5b";

  src = fetchurl {
    url = "ftp://ftp.proftpd.org/distrib/source/proftpd-${version}.tar.gz";
    sha256 = "1j2g9c25sabk89byj642c9npi8jg1alhvmy7zn6zib3q4jgpihdg";
  };

  propagatedBuildInputs = [
  ];

  buildInputs = [
    pkgs.libsodium
    pkgs.openssl
    pkgs.zlib
   ];

  enableParallelBuilding = true;
  configureFlags = [
    "--enable-openssl"
    "--with-modules=mod_sftp"
  ];

  meta = {
    homepage =http://www.proftpd.org/;
    description = "Highly configurable GPL-licensed FTP server software";
  };
}
