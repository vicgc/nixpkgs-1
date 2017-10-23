{ stdenv, fetchurl, fetchpatch, libxml2, findXMLCatalogs }:

stdenv.mkDerivation rec {
  name = "libxslt-1.1.31";

  src = fetchurl {
    url = "http://xmlsoft.org/sources/${name}.tar.gz";
    sha256 = "1azk48vf91nfajhm7k9cz3zrvh0aaq85ph37gqkl84c0ddmyj9fv";
  };

  patches = stdenv.lib.optional stdenv.isSunOS ./patch-ah.patch;

  outputs = [ "out" "doc" ];

  buildInputs = [ libxml2 ];

  propagatedBuildInputs = [ findXMLCatalogs ];

  configureFlags = [
    "--with-libxml-prefix=${libxml2}"
    "--without-python"
    "--without-crypto"
    "--without-debug"
    "--without-mem-debug"
    "--without-debugger"
  ];

  meta = {
    homepage = http://xmlsoft.org/XSLT/;
    description = "A C library and tools to do XSL transformations";
    license = "bsd";
    platforms = stdenv.lib.platforms.unix;
    maintainers = [ stdenv.lib.maintainers.eelco ];
  };
}
