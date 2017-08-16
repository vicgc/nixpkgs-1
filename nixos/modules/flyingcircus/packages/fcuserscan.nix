{ stdenv, fetchFromGitHub, rustPlatform }:

with rustPlatform;

buildRustPackage rec {
  name = "userscan-${version}";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "flyingcircusio";
    repo = "userscan";
    rev = "${version}";
    sha256 = "1vfcs8hzl84xdr6wjsdiraqpb56lgcd4cyzjb65ia1j4afd0div5";
  };

  cargoDepsSha256 = "1wmrb5x3x3cvsnslmlhmipr43x4chfk626vkh850aljd34sdh905";
  doCheck = true;

  meta = with stdenv.lib; {
    description = "Scan and register Nix store references from arbitrary files";
    homepage = https://github.com/flyingcircusio/userscan;
    license = with licenses; [ bsd3 ];
    platforms = platforms.all;
  };
}
