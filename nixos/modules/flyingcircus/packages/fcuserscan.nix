{ stdenv, fetchFromGitHub, rustPlatform }:

with rustPlatform;

buildRustPackage rec {
  name = "userscan-${version}";
  version = "4e9dfb0";

  src = fetchFromGitHub {
    owner = "flyingcircusio";
    repo = "userscan";
    rev = "${version}";
    sha256 = "1s08jc3ai24mljb8ylbhws6z6pjgg8p31sdgqmz40xic4gcq3h69";
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
