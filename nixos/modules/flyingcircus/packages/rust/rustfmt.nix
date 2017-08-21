{ stdenv, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  name = "rustfmt-${version}";
  version = "0.9.0";

  src = fetchFromGitHub {
    owner = "rust-lang-nursery";
    repo = "rustfmt";
    rev = "${version}";
    sha256 = "12l3ff0s0pzhcf5jbs8wqawjk4jghhhz8j6dq1n5201yvny12jlr";
  };

  cargoDepsSha256 = "0nwdgazl1ili8a3v5d2srz70f19b713m38jxcmkri3mcw1md3v3k";
  doCheck = true;

  meta = with stdenv.lib; {
    description = "A tool for formatting Rust code according to style guidelines";
    homepage = https://github.com/rust-lang-nursery/rustfmt;
    license = with licenses; [ mit asl20 ];
    platforms = platforms.all;
  };
}
