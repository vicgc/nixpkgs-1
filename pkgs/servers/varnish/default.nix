{ stdenv, fetchurl, pcre, libxslt, groff, ncurses, pkgconfig, readline, python
, pythonPackages }:

stdenv.mkDerivation rec {
  version = "4.0.5";
  name = "varnish-${version}";

  src = fetchurl {
    url = "http://varnish-cache.org/_downloads/${name}.tgz";
    sha256 = "1zqazfkz890p4rxfd4vzg4ipyikzlf40bdfb883w8fidj0rzl3yr";
  };

  buildInputs = [ pcre libxslt groff ncurses pkgconfig readline python
    pythonPackages.docutils];

  meta = {
    description = "Web application accelerator also known as a caching HTTP reverse proxy";
    homepage = "https://www.varnish-cache.org";
    license = stdenv.lib.licenses.bsd2;
    maintainers = [ stdenv.lib.maintainers.garbas ];
    platforms = stdenv.lib.platforms.linux;
  };
}
