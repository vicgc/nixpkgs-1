{ stdenv, fetchurl, callPackage }:

let
  # Note: the version MUST be one version prior to the version we're
  # building
  version = "1.24.0";

  # fetch hashes by running `print-hashes.sh 1.24.0`
  hashes = {
    i686-unknown-linux-gnu = "ad62f9bb1d9722d32de61d7f610c5ac1385cc6b29609f9b8a84027e4c3e44d62";
    x86_64-unknown-linux-gnu = "336cf7af6c857cdaa110e1425719fa3a1652351098dc73f156e5bf02ed86443c";
    armv7-unknown-linux-gnueabihf = "4138414be4d1664f3cb59c92e683b0ccd470d761efea31d858897b2c48bc5b95";
    aarch64-unknown-linux-gnu = "a981de306164b47f3d433c1d53936185260642849c79963af7e07d36b063a557";
    i686-apple-darwin = "1223e885d388eff0e0acb4ca71b6b6fa64929c83354bacc1a36185bc38527e94";
    x86_64-apple-darwin = "1aecba7cab4bc1a9e0e931c04aa00849e930b567d243da7b676ede8f527a2992";
  };

  platform =
    if stdenv.system == "i686-linux"
    then "i686-unknown-linux-gnu"
    else if stdenv.system == "x86_64-linux"
    then "x86_64-unknown-linux-gnu"
    else if stdenv.system == "armv7l-linux"
    then "armv7-unknown-linux-gnueabihf"
    else if stdenv.system == "aarch64-linux"
    then "aarch64-unknown-linux-gnu"
    else if stdenv.system == "i686-darwin"
    then "i686-apple-darwin"
    else if stdenv.system == "x86_64-darwin"
    then "x86_64-apple-darwin"
    else throw "missing bootstrap url for platform ${stdenv.system}";

  src = fetchurl {
     url = "https://static.rust-lang.org/dist/rust-${version}-${platform}.tar.gz";
     sha256 = hashes."${platform}";
  };

in callPackage ./binaryBuild.nix
  { inherit version src platform;
    buildRustPackage = null;
    versionType = "bootstrap";
  }
