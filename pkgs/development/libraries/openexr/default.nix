{ lib, stdenv, fetchurl, autoconf, automake, libtool, pkgconfig, zlib, ilmbase }:

stdenv.mkDerivation rec {
  name = "openexr-${lib.getVersion ilmbase}";

  src = fetchurl {
    url = "http://download.savannah.nongnu.org/releases/openexr/${name}.tar.gz";
    sha256 = "1kdf2gqznsdinbd5vcmqnif442nyhdf9l7ckc51410qm2gv5m6lg";
  };

  outputs = [ "out" "doc" ];

  preConfigure = ''
    ./bootstrap
  '';

  buildInputs = [ autoconf automake libtool pkgconfig ];
  propagatedBuildInputs = [ ilmbase zlib ];

  enableParallelBuilding = true;

  patches = [ ./bootstrap.patch ];

  meta = with stdenv.lib; {
    homepage = http://www.openexr.com/;
    license = licenses.bsd3;
    platforms = platforms.all;
    maintainers = with maintainers; [ wkennington ];
  };
}
