{ stdenv, fetchurl, openssl, python, zlib, libuv, v8, utillinux, http-parser
, pkgconfig, runCommand, which, libtool
}:

assert stdenv.system != "armv5tel-linux";

let
  deps = {
    inherit openssl zlib libuv;
  } // (stdenv.lib.optionalAttrs (!stdenv.isDarwin) {
    inherit http-parser;
  });

  sharedConfigureFlags = name: [
    "--shared-${name}"
    "--shared-${name}-includes=${builtins.getAttr name deps}/include"
    "--shared-${name}-libpath=${builtins.getAttr name deps}/lib"
  ];

  inherit (stdenv.lib) concatMap optional optionals maintainers licenses platforms;

  common = { version, src }: stdenv.mkDerivation {
    name = "nodejs-${version}";

    inherit version src;

    configureFlags = concatMap sharedConfigureFlags (builtins.attrNames deps) ++ [ "--without-dtrace" ];
    prePatch = ''
      patchShebangs .
      sed -i 's/raise.*No Xcode or CLT version detected.*/version = "7.0.0"/' tools/gyp/pylib/gyp/xcode_emulation.py
    '';

    postInstall = ''
      PATH=$out/bin:$PATH patchShebangs $out
    '';

    patches = stdenv.lib.optional stdenv.isDarwin ./no-xcode.patch;

    buildInputs = [ python which zlib libuv openssl ]
      ++ optionals stdenv.isLinux [ utillinux http-parser ]
      ++ optionals stdenv.isDarwin [ pkgconfig libtool ];
    setupHook = ./setup-hook.sh;

    enableParallelBuilding = true;
    dontDisableStatic = true;

    passthru.interpreterName = "nodejs";

    meta = {
      description = "Event-driven I/O framework for the V8 JavaScript engine";
      homepage = http://nodejs.org;
      license = licenses.mit;
      platforms = platforms.linux ++ platforms.darwin;
      priority = -10;
    };
  };

in {

  nodejs7 = common rec {
    version = "7.10.1";
    src = fetchurl {
      url = "http://nodejs.org/dist/v${version}/node-v${version}.tar.gz";
      sha256 = "baf060e5d3abb8fdebb8c2b28c4d8cde05d43acfd9fc687f21f4b7a3ff69745e";
    };

  };
}
