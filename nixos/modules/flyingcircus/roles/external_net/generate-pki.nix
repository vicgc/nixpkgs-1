{ stdenv
, easyrsa
, openvpn
, gawk
, resource_group ? "unknown-rg"
, location ? "standalone"
, caDir ? "/var/lib/openvpn-pki"
}:

stdenv.mkDerivation {
  name = "generate-pki";
  src = ./generate-pki.sh;
  propagatedBuildInputs = [ easyrsa openvpn gawk ];
  preferLocalBuild = true;
  phases = [ "installPhase" "fixupPhase" ];

  # substituteAll picks up these keys
  inherit easyrsa openvpn resource_group location caDir;
  installPhase = ''
    mkdir -p $out
    substituteAll $src $out/generate-pki
    chmod +x $out/generate-pki
  '';

  dontStrip = true;
  dontPatchELF = true;
  passthru = {
    inherit caDir;
    caCrt = "${caDir}/pki/ca.crt";
    serverCrt = "${caDir}/server.crt";
    serverKey = "${caDir}/server.key";
    clientCrt = "${caDir}/client.crt";
    clientKey = "${caDir}/client.key";
    dh = "${caDir}/pki/dh.pem";
    ta = "${caDir}/ta.key";
  };
}
