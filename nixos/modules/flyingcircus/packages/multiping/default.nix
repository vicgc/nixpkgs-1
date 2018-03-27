{ pkgs, stdenv, fetchFromGitHub, rustPlatform }:

with rustPlatform;

buildRustPackage rec {
  name = "multiping-${version}";
  version = "1.1.1";

  src = fetchFromGitHub {
    owner = "ckauhaus";
    repo = "multiping";
    rev = version;
    sha256 = "19whh7xzk2sqnrgkyw6gmmq5kn9pmbma5nnl6zc4iz4wa9slysl4";
  };
  cargoDepsSha256 = "0csfdih98c34l9978aa1fsfnjl8qb1p5mslskhl87phlf9wk9zqr";
  doCheck = true;
  RUSTFLAGS = "--cfg feature=\"oldglibc\"";

  meta = with stdenv.lib; {
    description = ''
      Pings multiple targets in parallel to check outgoing connectivity.
    '';
    homepage = "https://flyingcircus.io";
    license = with licenses; [ bsd3 ];
    platforms = platforms.all;
  };
}
