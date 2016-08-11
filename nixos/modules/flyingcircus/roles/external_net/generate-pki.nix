{ easyrsa
, openvpn
, stdenv
, resource_group ? "unknown-rg"
, location ? "standalone"
, caDir ? "/var/lib/openvpn-ca"
}:

stdenv.mkDerivation {
  inherit easyrsa openvpn resource_group location caDir;
  name = "generate-pki";
  src = ./generate-pki.sh;
  propagatedBuildInputs = [ easyrsa openvpn ];
  preferLocalBuild = true;
  phases = [ "installPhase" "fixupPhase" ];
  installPhase = ''
    mkdir -p $out
    substituteAll $src $out/generate-pki
    chmod +x $out/generate-pki
  '';
  dontStrip = true;
  dontPatchELF = true;
  passthru = {
    caCrt = "${caDir}/pki/ca.crt";
    serverCrt = "${caDir}/server.crt";
    serverKey = "${caDir}/server.key";
    clientCrt = "${caDir}/client.crt";
    clientKey = "${caDir}/client.key";
    dh = "${caDir}/pki/dh.pem";
    ta = "${caDir}/ta.key";
  };
}
