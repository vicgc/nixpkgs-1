{ stdenv, pythonPackages, fetchurl, dialog }:

pythonPackages.buildPythonApplication rec {
  version = "0.8.0";
  name = "certbot-${version}";

  src = fetchurl {
    url = "https://github.com/certbot/certbot/archive/v${version}.tar.gz";
    sha256 = "0z9m4kqqd9p2jhgx5g1xk7vb36w92mbmfr44vamnjxw6sarcgwmr";
  };

  propagatedBuildInputs = with pythonPackages; [
    acme
    ConfigArgParse
    configobj
    cryptography
    mock
    parsedatetime
    psutil3
    pyopenssl
    pyRFC3339
    python2-pythondialog
    pytz
    six
    zope_component
    zope_interface
 ];
  buildInputs = with pythonPackages; [ nose dialog ];

  patchPhase = ''
    substituteInPlace letsencrypt/notify.py --replace "/usr/sbin/sendmail" "/var/setuid-wrappers/sendmail"
  '';

  postInstall = ''
    for i in $out/bin/*; do
      wrapProgram "$i" --prefix PYTHONPATH : "$PYTHONPATH" \
                       --prefix PATH : "${dialog}/bin:$PATH"
    done
  '';

  meta = with stdenv.lib; {
    homepage = https://github.com/certbot/certbot;
    description = "ACME client that can obtain certs and extensibly update server configurations";
    platforms = platforms.unix;
    maintainers = [ maintainers.iElectric ];
    license = licenses.asl20;
  };
}
