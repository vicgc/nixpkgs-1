{ stdenv, fetchurl, iproute, lzo, openssl, pam, systemd, pkgconfig }:

with stdenv.lib;

stdenv.mkDerivation rec {
  name = "openvpn-2.4.3";

  src = fetchurl {
    url = "http://swupdate.openvpn.net/community/releases/${name}.tar.gz";
    sha256 = "0yc5rad2q5cm6rk0ali7f3di6v8vw23d3sy0cw5aaq198v5d7qyf";
  };

  buildInputs = [ iproute lzo openssl pam pkgconfig ] ++ optional stdenv.isLinux systemd;

  configureFlags = ''
    --enable-password-save
    --enable-iproute2
    --enable-systemd
    IPROUTE=${iproute}/sbin/ip
  '';

  postInstall = ''
    mkdir -p $out/share/doc/openvpn/examples
    cp -r sample/sample-config-files/ $out/share/doc/openvpn/examples
    cp -r sample/sample-keys/ $out/share/doc/openvpn/examples
    cp -r sample/sample-scripts/ $out/share/doc/openvpn/examples
  '';

  enableParallelBuilding = true;

  NIX_LDFLAGS = optionalString stdenv.isLinux "-lsystemd-daemon"; # hacky

  meta = {
    description = "A robust and highly flexible tunneling application";
    homepage = http://openvpn.net/;
    license = stdenv.lib.licenses.gpl2;
    maintainers = [ stdenv.lib.maintainers.viric ];
    platforms = stdenv.lib.platforms.linux;
  };
}
