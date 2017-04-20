{ stdenv, fetchFromGitHub, postgresql }:

let
  version = "0.1";
in
stdenv.mkDerivation {
  name = "rum-${version}";

  src = fetchFromGitHub {
    rev = "${version}";
    owner = "postgrespro";
    repo = "rum";
    sha256 = "0qbscy7nl8djnkh4anvywxq47zlamsi5bh08qcnmh4dwkny2931i";
  };

  buildInputs = [ postgresql ];

  makeFlags = [
    "USE_PGXS=1"
  ];

   installPhase =
   ''
     mkdir -p $out/{bin,lib}
     cp ./rum.so $out/lib
     mkdir -p $out/share/extension
     cp ./rum.control ./rum--1.0.sql $out/share/extension
   '';
 }