{ pkgs }:

with pkgs;

rec {
  WWWCurl = buildPerlPackage rec {
    name = "WWW-Curl-4.17";
    src = fetchurl {
      url = "mirror://cpan/authors/id/S/SZ/SZBALINT/${name}.tar.gz";
      sha256 = "1fmp9aib1kaps9vhs4dwxn7b15kgnlz9f714bxvqsd1j1q8spzsj";
    };
    buildInputs = [ curl ];
    patches = [ ./curl/WWWCurl-remove-symbol.patch ];
    preConfigure =
      ''
        substituteInPlace Makefile.PL --replace '"cpp"' '"gcc -E"'
      '';
    doCheck = false; # performs network access
  };

  CompressRawZlib = buildPerlPackage rec {
    name = "Compress-Raw-Zlib-2.071";

    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PM/PMQS/${name}.tar.gz";
      sha256 = "0dk7pcmhnl7n811q3p4rrz5ijdhz6jx367h6rypgvg1y39z4arfs";
    };

    preConfigure = ''
      cat > config.in <<EOF
        BUILD_ZLIB   = False
        INCLUDE      = ${zlib}/include
        LIB          = ${zlib}/lib
        OLD_ZLIB     = False
        GZIP_OS_CODE = AUTO_DETECT
      EOF
    '';

    # Try untested for now.  Upstream bug:
    # https://rt.cpan.org/Public/Bug/Display.html?id=119762
    doCheck = false && !stdenv.isDarwin;

    meta = {
      license = with stdenv.lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  IOCompress = buildPerlPackage {
    name = "IO-Compress-2.063";
    src = fetchurl {
      url = mirror://cpan/authors/id/P/PM/PMQS/IO-Compress-2.063.tar.gz;
      sha256 = "1198jqsfyshc8pc74dvn04gmqa0x6nwngkbf731zgd4chrjlylhd";
    };
    propagatedBuildInputs = [ perlPackages.CompressRawBzip2 CompressRawZlib ];
    meta = {
      homepage = http://search.cpan.org/perldoc?CPAN::Meta::Spec;
      description = "IO Interface to compressed data files/buffers";
      license = with stdenv.lib.licenses; [ artistic1 gpl1Plus ];
      platforms = stdenv.lib.platforms.linux;
    };
    doCheck = false;
  };

  CompressZlib = IOCompress;
}
