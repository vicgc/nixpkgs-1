{ stdenv, fetchurl, zlib, bzip2, libiconv, libxml2, openssl, ncurses, curl
, libmilter, pcre }:

stdenv.mkDerivation rec {
  name = "clamav-${version}";
  version = "0.99.3";

  src = fetchurl {
    url = "https://www.clamav.net/downloads/production/${name}.tar.gz";
    sha256 = "114f7qk3h0klgm0zzn2394n5spcn91vjc9mq6m03l2p0ls955yh0";
  };

  # don't install sample config files into the absolute sysconfdir folder
  postPatch = ''
    substituteInPlace Makefile.in --replace ' etc ' ' '
  '';

  buildInputs = [
    zlib bzip2 libxml2 openssl ncurses curl libiconv libmilter pcre
  ];

  configureFlags = [
    "--sysconfdir=/etc/clamav"
    "--with-zlib=${zlib}"
    "--disable-zlib-vcheck" # it fails to recognize that 1.2.10 >= 1.2.2
    "--with-libbz2-prefix=${bzip2}"
    "--with-iconv-dir=${libiconv}"
    "--with-xml=${libxml2}"
    "--with-openssl=${openssl}"
    "--with-libncurses-prefix=${ncurses}"
    "--with-libcurl=${curl}"
    "--with-pcre=${pcre}"
    "--enable-milter"
  ];

  postInstall = ''
    mkdir $out/etc
    cp etc/*.sample $out/etc
  '';

  meta = with stdenv.lib; {
    homepage = http://www.clamav.net;
    description = "Antivirus engine designed for detecting Trojans, viruses, malware and other malicious threats";
    license = licenses.gpl2;
    maintainers = with maintainers; [ phreedom robberer qknight ];
    platforms = platforms.linux;
  };
}
