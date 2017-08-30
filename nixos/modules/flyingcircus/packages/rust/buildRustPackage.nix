{ pkgs ? import <nixpkgs> {}
, stdenv ? pkgs.stdenv
, rust ? pkgs.rust
, rustRegistry ? pkgs.rustPlatform.rustRegistry
}:

# Builds a Rust package from src with all dependendies found in Cargo.lock.
# Don't forget to update the cargoDepsSha256 checksum when updating the sources.
# Due to the nature of fixed-output derivations strange compile errors may
# happen otherwise.

{ name
, release ? true
, src
, cargoDepsSha256
, buildInputs ? []
, ... } @ args:

let
  # Creates a "local-registry" directory which contains all dependendies needed
  # to compile `src`. Fixed output derivation to keep sandboxes happy.
  cargoLocalRegistry = src: sha256: rustRegistry: stdenv.mkDerivation {
    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

    inherit src;
    name = "${name}-cargo-deps";
    buildInputs = [ rust.cargo ];
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      export CARGO_HOME=$PWD
      cat <<__EOF__ > $CARGO_HOME/config
      [source.crates-io]
      replace-with = "nix-registry"

      [source.nix-registry]
      registry = "file://${rustRegistry}"
      __EOF__

      cargo fetch --locked
      mkdir $out
      cp $CARGO_HOME/registry/cache/*/*.crate $out
      ${pkgs.python3.interpreter} ${./vendor.py} -d $out ${rustRegistry}
    '';
    preferLocalBuild = true;
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = sha256;
  };

  targetDir = "target/${if release then "release" else "debug"}";

in stdenv.mkDerivation ({
  RUST_BACKTRACE = 1;
} // args // {
  inherit src;

  buildInputs = buildInputs ++ [
    rust.rustc
    rust.cargo
  ];

  postUnpack = ''
    export CARGO_HOME=$PWD/.cargo
    mkdir -p $CARGO_HOME
    cat <<__EOF__ > $CARGO_HOME/config
    [source.crates-io]
    replace-with = "nix-local-registry"

    [source.nix-local-registry]
    local-registry = "${cargoLocalRegistry src cargoDepsSha256 rustRegistry}"

    [build]
    jobs = $NIX_BUILD_CORES
    __EOF__
  '';

  buildPhase = ''
    runHook preBuild
    cargo build ${if release then "--release" else ""} --frozen
    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck
    cp -a ${targetDir} ${targetDir}.orig
    cargo test ${if release then "--release" else ""} --frozen
    rm -rf ${targetDir}
    mv ${targetDir}.orig ${targetDir}
    runHook PostCheck
  '';

  installPhase = ''
    runHook preInstall
    (
      cd ${targetDir}
      find . -maxdepth 1 -type f -perm -0100 \
        -print0 | xargs -0r install -D -t $out/bin
      find . -maxdepth 1 -type f \
        -name '*.rlib' -o -name '*.so' -o -name '.a' -o -name '*.dylib' \
        -print0 | xargs -0r install -D -t $out/lib
    )
    runHook postInstall
  '';

  distPhase = ''
    runHook preDist
    mkdir -p $out/tarballs
    tar cf $out/tarballs/${name}.tar `find . -maxdepth 1 -not -name . -not -name target -not -name .hg\* -not -name .cargo`
    runHook postDist
  '';
})
