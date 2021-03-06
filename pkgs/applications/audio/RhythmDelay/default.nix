{ stdenv, fetchFromGitHub, faust2jack, faust2lv2 }:
stdenv.mkDerivation rec {
  name = "RhythmDelay-${version}";
  version = "2.0";

  src = fetchFromGitHub {
    owner = "magnetophon";
    repo = "RhythmDelay";
    rev = "v${version}";
    sha256 = "0n938nm08mf3lz92k6v07k1469xxzmfkgclw40jgdssfcfa16bn7";
  };

  buildInputs = [ faust2jack faust2lv2 ];

  buildPhase = ''
    faust2jack -t 99999 RhythmDelay.dsp
    faust2lv2 -t 99999 RhythmDelay.dsp
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp RhythmDelay $out/bin/
    mkdir -p $out/lib/lv2
    cp -r RhythmDelay.lv2/ $out/lib/lv2
  '';

  meta = {
    description = "Tap a rhythm into your delay! For jack and lv2";
    homepage = https://github.com/magnetophon/RhythmDelay;
    license = stdenv.lib.licenses.gpl3;
    maintainers = [ stdenv.lib.maintainers.magnetophon ];
  };
}
