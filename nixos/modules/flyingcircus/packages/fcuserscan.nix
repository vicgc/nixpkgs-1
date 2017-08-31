{ pkgs, stdenv, fetchFromGitHub, rustPlatform }:

with rustPlatform;

buildRustPackage rec {
  name = "fc-userscan-${version}";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "flyingcircusio";
    repo = "userscan";
    rev = version;
    sha256 = "0gv4fqbv52yy3mkdvbbiv9ldfbs0238sh8hkh10rh3sy0rwl59ac";
  };

  cargoDepsSha256 = "0ddzxyn2ykmflxc4hw11vn7b7nk9l7bi83l4idx1m3qz0ywydcqc";
  propagatedBuildInputs = with pkgs; [ lzo ];
  doCheck = true;

  meta = with stdenv.lib; {
    description = "Scan and register Nix store references from arbitrary files";
    homepage = https://github.com/flyingcircusio/userscan;
    license = with licenses; [ bsd3 ];
    platforms = platforms.all;
  };
}
