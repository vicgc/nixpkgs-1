{ pkgs ? import <nixpkgs> { }
, stdenv ? pkgs.stdenv
, fetchgit ? pkgs.fetchgit
}:

pkgs.buildPerlPackage rec {
  name = "innotop-1.10.0";
  src = fetchgit {
    url = "https://github.com/innotop/innotop.git";
    rev = "96010a3814e4dfc82b2eccfea004c46057a5545d";
    sha256 = "0svi0fqr09vzgd8r9hfr89zc9vnz56p343zgmm5fndn0kbhxgiir";
  };

  patches = [ ./innotop.patch ];

  propagatedBuildInputs = [
    pkgs.perlPackages.DBI
    pkgs.perlPackages.DBDmysql
    pkgs.perlPackages.TermReadKey
  ];
  meta = {
    description = "innotop is a 'top' clone for MySQL with many features and flexibility.";
    license = stdenv.lib.licenses.gpl2;
  };
}
