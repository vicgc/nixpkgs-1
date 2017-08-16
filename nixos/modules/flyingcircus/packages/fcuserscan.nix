{ stdenv, fetchFromGitHub, rustPlatform }:

with rustPlatform;

buildRustPackage rec {
  name = "userscan-${version}";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "flyingcircusio";
    repo = "userscan";
    rev = "${version}";
    sha256 = "1pk0vl43k00flxsk3b6xjch7llkybws28z9r7iiqsdja0d96dwzn";
  };

  cargoDepsSha256 = "0p7p31py246f3rcdh8sm2w45qjx3qc72rc4k038077mv67nlsxsr";
  doCheck = true;

  meta = with stdenv.lib; {
    description = "Scan and register Nix store references from arbitrary files";
    homepage = https://github.com/flyingcircusio/userscan;
    license = with licenses; [ bsd3 ];
    platforms = platforms.all;
  };
}
