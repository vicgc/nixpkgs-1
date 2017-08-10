{ stdenv, fetchFromGitHub, rustPlatform, makeWrapper }:

with rustPlatform;

buildRustPackage rec {
  name = "ripgrep-${version}";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "BurntSushi";
    repo = "ripgrep";
    rev = "${version}";
    sha256 = "128sfczms14zgfbhgmf84jjlivd4q6i581rxirhz3kmpnnby18rz";
  };

  cargoDepsSha256 = "10bafvlq3dkr62d00b7gpaslwllmjax1j4z0y2cnw0x2qdkk48p1";
  doCheck = true;

  preFixup = ''
    mkdir -p "$out/man/man1"
    cp "$src/doc/rg.1" "$out/man/man1"
  '';

  meta = with stdenv.lib; {
    description = "A utility that combines the usability of The Silver Searcher with the raw speed of grep";
    homepage = https://github.com/BurntSushi/ripgrep;
    license = with licenses; [ unlicense ];
    maintainers = [ maintainers.tailhook ];
    platforms = platforms.all;
  };
}
