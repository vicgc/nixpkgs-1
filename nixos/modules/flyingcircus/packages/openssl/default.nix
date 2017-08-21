{ stdenv, fetchurl, perl
, withCryptodev ? false, cryptodevHeaders
}:

with stdenv.lib;

let
  opensslCrossSystem = stdenv.cross.openssl.system or
    (throw "openssl needs its platform name cross building");

  common = { version, release, sha256 }: stdenv.mkDerivation rec {
    name = "openssl-${version}${release}";

    src = fetchurl {
      url = "http://downloads.fcio.net/openssl/${name}.tar.gz";
      inherit sha256;
    };

    outputs = [ "out" "man" ];

    patches =
      optional (versionOlder version "1.1.0") ./use-etc-ssl-certs.patch
      ++ optional stdenv.isCygwin ./1.0.1-cygwin64.patch
      ++ optional (stdenv.isDarwin || (stdenv ? cross && stdenv.cross.libc == "libSystem")) ./darwin-arch.patch;

    nativeBuildInputs = [ perl ];
    buildInputs = stdenv.lib.optional withCryptodev cryptodevHeaders;

    # On x86_64-darwin, "./config" misdetects the system as
    # "darwin-i386-cc".  So specify the system type explicitly.
    configureScript =
      if stdenv.system == "x86_64-darwin" then "./Configure darwin64-x86_64-cc"
      else if stdenv.system == "x86_64-solaris" then "./Configure solaris64-x86_64-gcc"
      else "./config";

    configureFlags = [
      "shared"
      "--libdir=lib"
      "--openssldir=etc/ssl"
    ] ++ stdenv.lib.optionals withCryptodev [
      "-DHAVE_CRYPTODEV"
      "-DUSE_CRYPTODEV_DIGESTS"
    ];

    makeFlags = [
      "MANDIR=$(out)/share/man"
    ];

    # Parallel building is broken in OpenSSL.
    enableParallelBuilding = false;

    postInstall = ''
      # If we're building dynamic libraries, then don't install static
      # libraries.
      if [ -n "$(echo $out/lib/*.so $out/lib/*.dylib $out/lib/*.dll)" ]; then
          rm "$out/lib/"*.a
      fi

      # remove dependency on Perl at runtime
      rm -r $out/etc/ssl/misc $out/bin/c_rehash

      rmdir $out/etc/ssl/{certs,private}
    '';

    postFixup = ''
      # Check to make sure we don't depend on perl
      if grep -r '${perl}' $out; then
        echo "Found an erroneous dependency on perl ^^^" >&2
        exit 1
      fi
    '';

    setupHook = builtins.toFile "openssl-setup-hook"
      ''
        export SSL_CERT_FILE=/no-cert-file.crt
      '';

    crossAttrs = {
      # upstream patch: https://rt.openssl.org/Ticket/Display.html?id=2558
      postPatch = ''
         sed -i -e 's/[$][(]CROSS_COMPILE[)]windres/$(WINDRES)/' Makefile.shared
      '';
      preConfigure=''
        # It's configure does not like --build or --host
        export configureFlags="${concatStringsSep " " (configureFlags ++ [ opensslCrossSystem ])}"
        # WINDRES and RANLIB need to be prefixed when cross compiling;
        # the openssl configure script doesn't do that for us
        export WINDRES=${stdenv.cross.config}-windres
        export RANLIB=${stdenv.cross.config}-ranlib
      '';
      configureScript = "./Configure";
    };

    meta = {
      homepage = http://www.openssl.org/;
      description = "A cryptographic library that implements the SSL and TLS protocols";
      platforms = stdenv.lib.platforms.all;
      maintainers = [ stdenv.lib.maintainers.simons ];
      priority = 10; # resolves collision with ‘man-pages’
    };
  };

in {

  openssl_1_0_1 = common {
    version = "1.0.1";
    release = "u";
    sha256 = "0fb7y9pwbd76pgzd7xzqfrzibmc0vf03sl07f34z5dhm2b5b84j3";
  };

  openssl_1_0_2 = common {
    version = "1.0.2";
    release = "l";
    sha256 = "037kvpisc6qh5dkppcwbm5bg2q800xh2hma3vghz8xcycmdij1yf";
  };

  openssl_1_1_0 = common {
    version = "1.1.0";
    release = "f";
    sha256 = "0r97n4n552ns571diz54qsgarihrxvbn7kvyv8wjyfs9ybrldxqj";
  };

}
