# This file defines the source of Rust / cargo's crates registry
#
# buildRustPackage will automatically download dependencies from the registry
# version that we define here. If you're having problems downloading / finding
# a Rust library, try updating this to a newer commit.

{ stdenv, fetchFromGitHub, git }:

stdenv.mkDerivation {
  name = "rustRegistry-2018-02-25";

  src = fetchFromGitHub {
    owner = "rust-lang";
    repo = "crates.io-index";
    rev = "29073b8";
    sha256 = "1g42rfaj40jyryvhzrd474si1zg4y476nxnj9n0zr6179gcpk2iz";
  };
  phases = [ "unpackPhase" "installPhase" ];
  installPhase = ''
    mkdir -p $out
    cp -r ./* $out/
    cd $out
    git="${git}/bin/git"

    $git init
    $git config --local user.email "example@example.com"
    $git config --local user.name "example"
    $git add .
    $git commit --quiet -m 'Rust registry commit'

    touch $out/touch . "$out/.cargo-index-lock"
  '';
}
