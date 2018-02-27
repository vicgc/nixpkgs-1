{ pkgs, stdenv, rustPlatform }:

with rustPlatform;

buildRustPackage rec {
  name = "multiping-${version}";
  version = "1.0.0";

  src = ./multiping;
  cargoDepsSha256 = "1y4wqmn02s2a65ji9x4hpdwxlbpy87ajqnn8q59nbkzn3ys7wysz";
  doCheck = true;

  meta = with stdenv.lib; {
    description = ''
      Pings multiple targets in parallel to check outgoing connectivity.
    '';
    homepage = "https://flyingcircus.io";
    license = with licenses; [ bsd3 ];
    platforms = platforms.all;
  };
}
