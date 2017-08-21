{ stdenv, fetchurl, unzip, xorg, libjpeg, fetchFromGitHub, autoreconfHook }:

stdenv.mkDerivation rec {
  name = "jasper-${version}";
  version ="1.900.31";

  src = fetchFromGitHub {
    repo = "jasper";
    owner = "mdadams";
    rev = "version-${version}";
    sha256 = "1xv32769qf8977hb813n5wjsrvh0cinshsg8c7p8gcf54zi38hvr";
  };

  nativeBuildInputs = [ unzip autoreconfHook ];
  propagatedBuildInputs = [ libjpeg ];

  configureFlags = "--enable-shared";

  enableParallelBuilding = true;

  meta = {
    homepage = https://www.ece.uvic.ca/~frodo/jasper/;
    description = "JPEG2000 Library";
  };
}
