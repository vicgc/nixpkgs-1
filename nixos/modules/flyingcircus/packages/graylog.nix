# backported from 16.03
{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "2.1.0";
  name = "graylog-${version}";

  src = fetchurl {
    url = "https://packages.graylog2.org/releases/graylog/graylog-${version}.tgz";
    sha256 = "09rcgjxnv235a9rvyfcfdjvmr3rjb0jg5sph8sqvzgspvas9pgvn";
  };

  src_sso = fetchurl {
    url= "https://github.com/Graylog2/graylog-plugin-auth-sso/releases/download/1.0.1/graylog-plugin-auth-sso-1.0.3.jar";
    sha256 ="1qraaf3pm2i7vhvrls9fspc6mxn9hf5n49298hza9rmhpc8izdzv";
  };

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    mkdir -p $out
    cp -r {graylog.jar,lib,bin,plugin,data} $out
    cp ${src_sso.outPath} $out/plugin/
  '';

  meta = with stdenv.lib; {
    description = "Open source log management solution";
    homepage    = https://www.graylog.org/;
    license     = licenses.gpl3;
    platforms   = platforms.unix;
    maintainers = [ maintainers.fadenb ];
  };
}
