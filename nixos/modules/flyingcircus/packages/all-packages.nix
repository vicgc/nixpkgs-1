{ pkgs ? (import <nixpkgs> {})
, lib ? pkgs.lib
, stdenv ? pkgs.stdenv
}:

let
  fetchFromGitHub = (import <nixpkgs> {}).fetchFromGitHub;

  pkgs_17_09_src = fetchFromGitHub {
    owner = "flyingcircusio";
    repo = "nixpkgs";
    rev = "c0f9781698dbd5fefee7dafccb04c34c76fec01a";
    sha256 = "1hbhpbxka0kf3976mh71vwpwr9mcfg3savi7ixk2n57n588dc1i2";
  };
  pkgs_17_09 = import pkgs_17_09_src {};

in rec {
  inherit pkgs_17_09_src;

  boost159 = pkgs.callPackage ./boost/1.59.nix { };
  boost160 = pkgs.callPackage ./boost/1.60.nix { };
  busybox = pkgs.callPackage ./busybox { };

  cacert = pkgs.callPackage ./cacert.nix { };
  clamav = pkgs.callPackage ./clamav.nix { };
  collectd = pkgs.callPackage ./collectd {
    libsigrok = null;
    libvirt = null;
    lm_sensors = null;  # probably not seen on VMs
    lvm2 = null;        # dito
  };
  collectdproxy = pkgs.callPackage ./collectdproxy { };
  coturn = pkgs.callPackage ./coturn { libevent = libevent.override {
    withOpenSSL = true;
    };};
  cron = pkgs.callPackage ./cron.nix { };
  curl = pkgs.callPackage ./curl rec {
    fetchurl = stdenv.fetchurlBoot;
    zlibSupport = true;
    sslSupport = true;
    scpSupport = true;
  };

  dnsmasq = pkgs.callPackage ./dnsmasq.nix { };

  easyrsa3 = pkgs.callPackage ./easyrsa { };
  elasticsearch = pkgs.callPackage ./elasticsearch { };
  electron = pkgs.callPackage ./electron.nix {
    gconf = pkgs.gnome.GConf;
  };
  expat = pkgs.callPackage ./expat.nix { };

  fcbox = pkgs.callPackage ./fcbox { };
  fcmaintenance = pkgs.callPackage ./fcmaintenance { };
  fcmanage = pkgs.callPackage ./fcmanage { };
  fcsensuplugins = pkgs.callPackage ./fcsensuplugins { };
  fcuserscan = pkgs.callPackage ./fcuserscan.nix { } ;

  grafana = pkgs_17_09.grafana;
  graylog = pkgs.callPackage ./graylog.nix { };

  http-parser = pkgs.callPackage ./http-parser {
    gyp = pkgs.pythonPackages.gyp;
  };

  imagemagick = imagemagickBig.override {
    ghostscript = null;
  };
  imagemagickBig = pkgs.callPackage ./ImageMagick { };

  iptables = pkgs_17_09.iptables;

  influxdb = pkgs.callPackage ./influxdb.nix { };
  innotop = pkgs.callPackage ./percona/innotop.nix { };

  kibana = pkgs.callPackage ./kibana.nix { };

  libevent = pkgs.callPackage ./libevent.nix { };

  libidn = pkgs.callPackage ./libidn.nix { };

  linux = linux_4_4;
  linux_4_4 = pkgs.callPackage ./kernel/linux-4.4.nix {
    kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
  };
  linuxPackages = linuxPackages_4_4;
  linuxPackages_4_4 = pkgs.recurseIntoAttrs
    (pkgs.linuxPackagesFor linux_4_4 linuxPackages_4_4);

  mc = pkgs.callPackage ./mc.nix { };
  mariadb = pkgs.callPackage ./mariadb.nix { };
  mailx = pkgs.callPackage ./mailx.nix { };
  memcached = pkgs.callPackage ./memcached.nix { };
  mongodb = mongodb_3_0;
  mongodb_3_0 = pkgs.callPackage ./mongodb/3_0.nix {
    sasl = pkgs.cyrus_sasl;
  };
  mongodb_3_2 = pkgs.callPackage ./mongodb {
    sasl = pkgs.cyrus_sasl;
  };

  nagiosPluginsOfficial = pkgs.callPackage ./nagios-plugins-official-2.x.nix {};

  nginx =
    let
      nginxModules = import ./nginx/modules.nix { inherit pkgs; };
    in
    pkgs.callPackage ./nginx/stable.nix {
      modules = [ nginxModules.rtmp nginxModules.dav nginxModules.moreheaders ];
    };

  nix = pkgs_17_09.nix;

  inherit (pkgs.callPackage ./nodejs { libuv = pkgs.libuvVersions.v1_9_1; })
    nodejs4 nodejs6 nodejs7;

  inherit (pkgs.callPackages ./openssl {
      fetchurl = pkgs.fetchurlBoot;
      cryptodevHeaders = pkgs.linuxPackages.cryptodev.override {
        fetchurl = pkgs.fetchurlBoot;
        onlyHeaders = true;
      };
    })
    openssl_1_0_2 openssl_1_1_0 openssl_1_0_1;
  openssl = openssl_1_0_2;

  osm2pgsql = pkgs.callPackage ./osm2pgsql.nix { };
  osrm-backend = pkgs.callPackage ./osrm-backend { };

  pcre = pkgs.callPackage ./pcre.nix { };
  pcre-cpp = pcre.override { variant = "cpp"; };
  percona = percona57;
  percona57 = pkgs.callPackage ./percona/5.7.nix { boost = boost159; };
  percona56 = pkgs.callPackage ./percona/5.6.nix { boost = boost159; };

  postgis = pkgs.callPackage ./postgis { };
  inherit (pkgs.callPackages ./postgresql { })
    postgresql93
    postgresql94
    postgresql95
    postgresql96;

  rum = pkgs.callPackage ./postgresql/rum { postgresql = postgresql96; };

  inherit (pkgs.callPackages ./php { })
    php55
    php56
    php70;

  php70Packages = pkgs_17_09.php70Packages;

  postfix = pkgs.callPackage ./postfix/3.0.nix { };
  powerdns = pkgs.callPackage ./powerdns.nix { };

  prometheus = pkgs_17_09.prometheus;
  prometheus-haproxy-exporter = pkgs_17_09.prometheus-haproxy-exporter;

  qemu = pkgs.callPackage ./qemu/qemu-2.8.nix {
    inherit (pkgs.darwin.apple_sdk.frameworks) CoreServices Cocoa;
    x86Only = true;
  };
  qpress = pkgs.callPackage ./percona/qpress.nix { };

  rabbitmq_server = pkgs.callPackage ./rabbitmq-server.nix { };
  rabbitmq_delayed_message_exchange =
    pkgs.callPackage ./rabbitmq_delayed_message_exchange.nix { };

  remarshal = pkgs_17_09.remarshal;
  ripgrep = pkgs_17_09.ripgrep;

  rust = pkgs.callPackage ./rust/default.nix { };
  rustPlatform = pkgs.recurseIntoAttrs (makeRustPlatform rust);
  makeRustPlatform = rust: lib.fix (self:
    let
      callPackage = pkgs.newScope self;
    in rec {
      inherit rust;

      rustRegistry = pkgs.callPackage ./rust/rust-packages.nix { };

      buildRustPackage = pkgs.callPackage ./rust/buildRustPackage.nix {
        inherit rust rustRegistry;
      };
    });
  rustfmt = pkgs.callPackage ./rust/rustfmt.nix { };
  rust-bindgen = pkgs.callPackage ./rust/bindgen.nix { };

  # compatibility fixes for 15.09
  rustCargoPlatform = rustPlatform;
  rustStable = rustPlatform;
  rustUnstable = rustPlatform;

  sensu = pkgs.callPackage ./sensu { };

  telegraf = pkgs.callPackage ./telegraf {
    inherit (pkgs_17_09) buildGoPackage fetchgit;
  };

  uchiwa = pkgs.callPackage ./uchiwa { };

  varnish =
    (pkgs.callPackage ../../../../pkgs/servers/varnish { }).overrideDerivation
    (old: {
      buildFlags = "localstatedir=/var/spool";
    });
  vulnix = pkgs.callPackage ./vulnix { };

  xtrabackup = pkgs.callPackage ./percona/xtrabackup.nix { };

  yarn = pkgs.callPackage ./yarn.nix { nodejs = nodejs7; };

}
