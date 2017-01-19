{ stdenv, fetchurl, openssl, python, zlib, libuv, v8, utillinux, http-parser
, pkgconfig, runCommand, which, libtool
, preBuild ? ""
, extraConfigFlags ? []
, extraBuildInputs ? []
, patches ? [],
 ...
}:

assert stdenv.system != "armv5tel-linux";

let
  version = "4.6.0";

  src = fetchurl {
    url = "http://nodejs.org/dist/v${version}/node-v${version}.tar.xz";
    sha256 = "1566q1kkv8j30fgqx8sm2h8323f38wwpa1hfb10gr6z46jyhv4a2";
  };

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

in stdenv.mkDerivation {

  inherit version src preBuild;

  name = "nodejs-${version}";

  configureFlags = concatMap sharedConfigureFlags (builtins.attrNames deps) ++ [ "--without-dtrace" ] ++ extraConfigFlags;
  dontDisableStatic = true;
  prePatch = ''
    patchShebangs .
    sed -i 's/raise.*No Xcode or CLT version detected.*/version = "7.0.0"/' tools/gyp/pylib/gyp/xcode_emulation.py
  '';

  postInstall = ''
    PATH=$out/bin:$PATH patchShebangs $out
  '';

  patches = patches ++ stdenv.lib.optionals stdenv.isDarwin [ ./no-xcode.patch ];

  buildInputs = extraBuildInputs
    ++ [ python which zlib libuv openssl ]
    ++ optionals stdenv.isLinux [ utillinux http-parser ]
    ++ optionals stdenv.isDarwin [ pkgconfig libtool ];
  setupHook = ./setup-hook.sh;

  enableParallelBuilding = true;

  passthru.interpreterName = "nodejs";

  meta = {
    description = "Event-driven I/O framework for the V8 JavaScript engine";
    homepage = http://nodejs.org;
    license = licenses.mit;
    maintainers = [ maintainers.goibhniu maintainers.havvy ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
