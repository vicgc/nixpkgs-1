{ fetchurl, stdenv, acl, openssl, libxml2, attr, zlib, bzip2, e2fsprogs, xz
, sharutils }:

stdenv.mkDerivation rec {
  name = "libarchive-3.3.2";

  src = fetchurl {
    urls = [
      "${meta.homepage}/downloads/${name}.tar.gz"
    ];
    sha256 = "1km0mzfl6in7l5vz9kl09a88ajx562rw93ng9h2jqavrailvsbgd";
  };

  patches = [
    ./CVE-2017-14166.patch
    ./CVE-2017-14502.patch
  ];

  buildInputs = [ sharutils libxml2 zlib bzip2 openssl xz ] ++
    stdenv.lib.optionals stdenv.isLinux [ e2fsprogs attr acl ];

  preBuild = if stdenv.isCygwin then ''
    echo "#include <windows.h>" >> config.h
  '' else null;

  preFixup = ''
    sed 's|-lcrypto|-L${openssl}/lib -lcrypto|' -i $out/lib/libarchive.la
  '';

  meta = {
    description = "Multi-format archive and compression library";
    longDescription = ''
      This library has code for detecting and reading many archive formats and
      compressions formats including (but not limited to) tar, shar, cpio, zip, and
      compressed with gzip, bzip2, lzma, xz, ..
    '';
    homepage = http://libarchive.org;
    license = stdenv.lib.licenses.bsd3;
    platforms = with stdenv.lib.platforms; all;
    maintainers = with stdenv.lib.maintainers; [ jcumming ];
  };
}
