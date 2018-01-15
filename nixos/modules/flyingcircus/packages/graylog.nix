# backported from 16.03
{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "2.4.0";
  name = "graylog-${version}";

  src = fetchurl {
    url = "https://packages.graylog2.org/releases/graylog/graylog-${version}.tgz";
    sha256 = "12ipp1bji0ss0d20dpqx8d6x3p3h38qdfdy98qy37mjy0fi22vpq";
  };
  src_logstash = fetchurl {
    url = "https://github.com/sivasamyk/graylog2-input-lumberjack/releases/download/v1.0.0/graylog2-input-lumberjack-1.0.0-rc1.jar";
    sha256 = "1854pvqw2ffgy7bhkk5savybwlvhlasxdpl1yph87znsyinzfrmr";
  };

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    mkdir -p $out
    cp -r {graylog.jar,lib,bin,plugin,data} $out
    cp ${src_logstash.outPath} $out/plugin/
  '';

  meta = with stdenv.lib; {
    description = "Open source log management solution";
    homepage    = https://www.graylog.org/;
    license     = licenses.gpl3;
    platforms   = platforms.unix;
  };
}
