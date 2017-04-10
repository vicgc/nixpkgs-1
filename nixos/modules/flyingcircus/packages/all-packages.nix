{ pkgs ? (import <nixpkgs> {}) }:

let
  lib = pkgs.lib;
  pkgs_17_03 = (import ((import <nixpkgs> {}).fetchFromGitHub {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "645137cdc9ba4e3e30bc3fd897b7d4c0b53685e5";
      sha256 = "1jsckl6v3hl8nfp5wr3x2g9ga5d0rabfkyjhaj6aq60a7jz2gxwa";
  }) {});
in
rec {

  boost159 = pkgs.callPackage ./boost/1.59.nix { };
  boost160 = pkgs.callPackage ./boost/1.60.nix { };

  cacert = pkgs.callPackage ./cacert.nix { };
  clamav = pkgs.callPackage ./clamav.nix { };
  collectd = pkgs.callPackage ./collectd {
    libsigrok = null;
    libvirt = null;
    lm_sensors = null;  # probably not seen on VMs
    lvm2 = null;        # dito
  };
  collectdproxy = pkgs.callPackage ./collectdproxy { };

  cron = pkgs.callPackage ./cron.nix { };
  curl = pkgs.callPackage ./curl rec {
    fetchurl = pkgs.stdenv.fetchurlBoot;
    zlibSupport = true;
    sslSupport = zlibSupport;
    scpSupport = zlibSupport;
  };

  dnsmasq = pkgs.callPackage ./dnsmasq.nix { };

  easyrsa3 = pkgs.callPackage ./easyrsa { };
  elasticsearch = pkgs.callPackage ./elasticsearch { };
  electron = pkgs.callPackage ./electron.nix {
    gconf = pkgs.gnome.GConf;
  };
  expat = pkgs.callPackage ./expat.nix { };

  fcmaintenance = pkgs.callPackage ./fcmaintenance { };
  fcmanage = pkgs.callPackage ./fcmanage { };
  fcsensuplugins = pkgs.callPackage ./fcsensuplugins { };

  grafana = pkgs_17_03.grafana;

  graylog = pkgs.callPackage ./graylog.nix { };

  http-parser = pkgs.callPackage ./http-parser {
    gyp = pkgs.pythonPackages.gyp;
  };

  influxdb1_2 = pkgs_17_03.influxdb ;

  innotop = pkgs.callPackage ./percona/innotop.nix { };

  kibana = pkgs.callPackage ./kibana.nix { };

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
  mongodb_3_0 = pkgs.callPackage ../../../../pkgs/servers/nosql/mongodb {
    pcre = pcre-cpp;
    sasl = pkgs.cyrus_sasl;
  };
  mongodb_3_2 = pkgs.callPackage ./mongodb {
    pcre = pcre-cpp;
    sasl = pkgs.cyrus_sasl;
  };

  nagiosPluginsOfficial = pkgs.callPackage ./nagios-plugins-official-2.x.nix {};

  nix = pkgs_17_03.nix;

  nginx =
    let
      nginxModules = import ./nginx/modules.nix { inherit pkgs; };
    in
    pkgs.callPackage ./nginx/stable.nix {
      modules = [ nginxModules.rtmp nginxModules.dav nginxModules.moreheaders ];
    };

  inherit (pkgs.callPackage ./nodejs { libuv = pkgs.libuvVersions.v1_9_1; })
    nodejs4 nodejs6 nodejs7;

  inherit (pkgs.callPackages ./openssl {
      fetchurl = pkgs.fetchurlBoot;
      cryptodevHeaders = pkgs.linuxPackages.cryptodev.override {
        fetchurl = pkgs.fetchurlBoot;
        onlyHeaders = true;
      };
    })
    openssl_1_0_2 openssl_1_1_0;
  openssl = openssl_1_0_2;

  osm2pgsql = pkgs.callPackage ./osm2pgsql.nix { };

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

  postfix = pkgs.callPackage ./postfix/3.0.nix { };
  powerdns = pkgs.callPackage ./powerdns.nix { };

  qemu = pkgs.callPackage ./qemu/qemu-2.8.nix {
    inherit (pkgs.darwin.apple_sdk.frameworks) CoreServices Cocoa;
    x86Only = true;
  };
  qpress = pkgs.callPackage ./percona/qpress.nix { };

  rabbitmq_server = pkgs.callPackage ./rabbitmq-server.nix { };
  rabbitmq_delayed_message_exchange =
    pkgs.callPackage ./rabbitmq_delayed_message_exchange.nix { };

  sensu = pkgs_17_03.sensu;

  uchiwa = pkgs_17_03.uchiwa;

  varnish =
    (pkgs.callPackage ../../../../pkgs/servers/varnish { }).overrideDerivation
    (old: {
      buildFlags = "localstatedir=/var/spool";
    });
  vulnix = pkgs.callPackage ./vulnix { };

  xtrabackup = pkgs.callPackage ./percona/xtrabackup.nix { };

}
