{ lib, bundlerEnv, ruby, python2, pkgs, which, defaultGemConfig, zlib, libxml2, graphicsmagick, pkgconfig, imagemagickBig }:

bundlerEnv {
  name = "sensu-0.22.1";

  gemfile = ./Gemfile;
  lockfile = ./Gemfile.lock;
  gemset = ./gemset.nix;

  gemConfig = defaultGemConfig // {
    libxml-ruby = attrs: {
      buildInputs = [ zlib ];
      preInstall = ''
        bundle config build.libxml-ruby "--use-system-libraries --with-xml2-lib=${libxml2}/lib --with-xml2-include=${libxml2}/include/libxml2"
      '';
    };
    rmagick = attrs: {
      buildInputs = [ which graphicsmagick pkgconfig imagemagickBig ];
    };
    mysql = attrs: {
      buildInputs = with pkgs; [ mysql ];
    };
    redis = attrs: {
      buildInputs = with pkgs; [ redis ];
    };
    memcached = attrs: {
      buildInputs = with pkgs; [ cyrus_sasl ];
    };
};

  meta = with lib; {
    description = "A monitoring framework that aims to be simple, malleable, and scalable";
    homepage    = http://sensuapp.org/;
    license     = licenses.mit;
    maintainers = with maintainers; [ theuni ];
    platforms   = platforms.unix;
  };

}
