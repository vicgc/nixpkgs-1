{ stdenv, fetchFromGitHub, rustPlatform }:

with rustPlatform;

buildRustPackage rec {
  name = "fc-userscan-${version}";
  version = "e0ae456";

  src = fetchFromGitHub {
    owner = "flyingcircusio";
    repo = "userscan";
    rev = "${version}";
    sha256 = "03fib3jhxl7fzb1a662yx0hldkpv0ccyr88arn1vpvkadf4hb7yn";
  };

  cargoDepsSha256 = "0hz73mf4rx4qk9cjnwda2i93kiprjmmcric14j6glzi3x80nr51z";
  doCheck = true;

  meta = with stdenv.lib; {
    description = "Scan and register Nix store references from arbitrary files";
    homepage = https://github.com/flyingcircusio/userscan;
    license = with licenses; [ bsd3 ];
    platforms = platforms.all;
  };
}
