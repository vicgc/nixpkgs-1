{ stdenv, fetchurl, fetchpatch, pkgconfig, glib, intltool, gnutls, libproxy
, gsettings_desktop_schemas }:

let
  ver_maj = "2.44";
  ver_min = "0";
in
stdenv.mkDerivation rec {
  name = "glib-networking-${ver_maj}.${ver_min}";

  src = fetchurl {
    url = "mirror://gnome/sources/glib-networking/${ver_maj}/${name}.tar.xz";
    sha256 = "8f8a340d3ba99bfdef38b653da929652ea6640e27969d29f7ac51fbbe11a4346";
  };
  patches = [(fetchpatch {
    name = "fix-certificates.patch";
    url = "https://git.gnome.org/browse/glib-networking/patch"
      + "/?id=44d02b8c57e24f0a796d75b6270ecee265f35f6f";
    sha256 = "0kfvk4ci786hca794c1c3c8ihh9lgp7qrj887c28ik5ndm4w55i3";
  })];

  configureFlags = "--with-ca-certificates=/etc/ssl/certs/ca-certificates.crt";

  preBuild = ''
    sed -e "s@${glib}/lib/gio/modules@$out/lib/gio/modules@g" -i $(find . -name Makefile)
  '';

  nativeBuildInputs = [ pkgconfig intltool ];
  propagatedBuildInputs = [ glib gnutls libproxy gsettings_desktop_schemas ];

  doCheck = false; # tests need to access the certificates (among other things)

  meta = with stdenv.lib; {
    description = "Network-related giomodules for glib";
    license = licenses.lgpl2Plus;
    platforms = platforms.unix;
  };
}

