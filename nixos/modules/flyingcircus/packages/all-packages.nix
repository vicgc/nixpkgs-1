{ pkgs ? (import <nixpkgs> {})
, lib ? pkgs.lib
, stdenv ? pkgs.stdenv
}:

let
  fetchFromGitHub = (import <nixpkgs> {}).fetchFromGitHub;

  pkgs_17_09_src = fetchFromGitHub {
    owner = "flyingcircusio";
    repo = "nixpkgs";
    rev = "3092d86";
    sha256 = "07bc8rkyg49d1w5j7zfzf4aa15hgzrrkf6girv3616f29j6gcmin";
  };
  pkgs_17_09 = import pkgs_17_09_src {};

in rec {
  inherit pkgs_17_09_src;

  # Security update - needed by qemu and others #26909
  audiofile = pkgs_17_09.audiofile;

  boost159 = pkgs.callPackage ./boost/1.59.nix { };
  boost160 = pkgs.callPackage ./boost/1.60.nix { };
  bundlerApp = pkgs_17_09.bundlerApp;
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
  docsplit = pkgs.callPackage ./docsplit { };

  easyrsa3 = pkgs.callPackage ./easyrsa { };
  elasticsearch2 = pkgs_17_09.elasticsearch2;
  elasticsearch5 = pkgs_17_09.elasticsearch5;
  electron = pkgs.callPackage ./electron.nix {
    gconf = pkgs.gnome.GConf;
  };
  expat = pkgs.callPackage ./expat.nix { };

  fcbox = pkgs.callPackage ./fcbox { };
  fcmaintenance = pkgs.callPackage ./fcmaintenance { };
  fcmanage = pkgs.callPackage ./fcmanage { };
  fcsensuplugins = pkgs.callPackage ./fcsensuplugins { };
  fcuserscan = pkgs.callPackage ./fcuserscan.nix { } ;
  firefox = pkgs_17_09.firefox;

  grafana = pkgs_17_09.callPackage ./grafana { };
  graphicsmagick = pkgs_17_09.graphicsmagick;
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

  kibana = pkgs_17_09.kibana;

  libevent = pkgs.callPackage ./libevent.nix { };
  libidn = pkgs.callPackage ./libidn.nix { };
  libreoffice = pkgs_17_09.libreoffice;

  linux = linux_4_4;
  linux_4_4 = pkgs.callPackage ./kernel/linux-4.4.nix {
    kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
  };
  linuxPackages = linuxPackages_4_4;
  linuxPackages_4_4 =
    # This is hacky, but works for now. linuxPackagesFor is intended to
    # automatically customize for each kernel but making that overridable
    # is beyond my comprehension right now.
    let
      default_pkgs = pkgs.recurseIntoAttrs
      (pkgs.linuxPackagesFor linux_4_4 linuxPackages_4_4);
    in
      lib.overrideExisting default_pkgs { inherit virtualbox virtualboxGuestAdditions; };

  mc = pkgs.callPackage ./mc.nix { };
  mariadb = pkgs.callPackage ./mariadb.nix { };
  mailx = pkgs.callPackage ./mailx.nix { };
  mailutils = pkgs_17_09.mailutils;
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

  nodejs4 = pkgs_17_09.nodejs-4_x;
  nodejs6 = pkgs_17_09.nodejs-6_x;
  nodejs8 = pkgs_17_09.nodejs-8_x;

  inherit (pkgs.callPackage ./nodejs { libuv = pkgs.libuvVersions.v1_9_1; })
    nodejs7;

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

  samba = pkgs_17_09.samba;
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
  virtualbox = pkgs_17_09.virtualbox;
  # The guest additions need to use the kernel we're actually building so we
  # have to callPackage them instead of using the pre-made package.
  virtualboxGuestAdditions = pkgs_17_09.callPackage "${pkgs_17_09_src}/pkgs/applications/virtualization/virtualbox/guest-additions" { kernel = linux_4_4; };
  vulnix = pkgs.callPackage ./vulnix { };

  xtrabackup = pkgs.callPackage ./percona/xtrabackup.nix { };
  xulrunner = pkgs_17_09.xulrunner;

  yarn = pkgs.callPackage ./yarn.nix { nodejs = nodejs7; };

}
