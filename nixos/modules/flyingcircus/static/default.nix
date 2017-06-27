{ lib, ... }:
with lib;
{
  options = {

    flyingcircus.static = mkOption {
      type = types.attrsOf types.attrs;
      default = { };
      description = "Static lookup tables for site-specific information";
    };

  };

  config = {

    flyingcircus.static.locations = {
      "whq" = { id = 0; site = "Halle"; };
      "yard" = { id = 1; site = "Halle"; };
      "rzob" = { id = 2; site = "Oberhausen"; };
      "dev" = { id = 3; site = "Halle"; };
      "rzrl1" = { id = 4; site = "Norderstedt"; };
    };

    # Note: this list of VLAN classes should be kept in sync with
    # fc.directory/src/fc/directory/vlan.py
    flyingcircus.static.vlans = {
      # management (grey): BMC, switches, tftp, remote console
      "1" = "mgm";
      # frontend (yellow): access from public Internet
      "2" = "fe";
      # servers/backend (red): RG-internal (app, database, ...)
      "3" = "srv";
      # storage (black): VM storage access (Ceph)
      "4" = "sto";
      # workstation (green): office network
      "5" = "ws";
      # transfer (blue): primary router uplink
      "6" = "tr";
      # guest (green): office wifi for unknown users
      "7" = "gue";
      # storage backend (yellow): Ceph replication and migration
      "8" = "stb";
      # transfer 2 (blue): secondary router-router connection
      "14" = "tr2";
      # gocept office
      "15" = "gocept";
      # frontend (yellow): additional fe needed on some switches
      "16" = "fe2";
      # servers/backend (red): additional srv needed on some switches
      "17" = "srv2";
      # transfer 3 (blue): tertiary router-router connection
      "18" = "tr3";
      # dynamic hardware pool: local endpoints for Kamp DHP tunnels
      "19" = "dhp";
    };

    flyingcircus.static.nameservers = {
      # ns.$location.gocept.net, ns2.$location.gocept.net
      # We are currently not using IPv6 resolvers as we have seen obscure bugs
      # when enabling them, like weird search path confusion that results in
      # arbitrary negative responses, combined with the rotate flag.
      #
      # This seems to be https://sourceware.org/bugzilla/show_bug.cgi?id=13028
      # which is fixed in glibc 2.22 which is included in NixOS 16.03.
      dev = [ "172.20.3.1" "172.20.2.7" "172.20.2.44" ];
      rzob = ["195.62.125.5" "195.62.125.135"];
      rzrl1 = ["172.24.32.3" "172.24.48.4"];
      whq = ["212.122.41.143" "212.122.41.169"];

      # We'd like to add reliable open and trustworthy DNS servers here, but
      # I didn't find reliable ones. FoeBud and Germany Privacy Foundation and
      # others had long expired listings and I don't trust the remaining ones
      # to stay around. So, Google DNS it is.
      standalone = [ "8.8.8.8" "8.8.4.4" ];
    };

    flyingcircus.static.directory = {
      proxy_ips =
      [ "195.62.125.6"
        "195.62.125.11"
        "2a02:248:101:62::108c"
        "2a02:248:101:62::dd"
        "2a02:248:101:63::d4"
      ];
    };

    flyingcircus.static.ntpservers = {
      # Those are the routers and backup servers. This needs to move to the
      # directory service discovery.
      dev = [ "barney" "eddie" "patty"];
      rzob = [ "carme" "cartman07" "cartman11" "kenny00" "cartman12" "kenny01" "cartman10" "iocaste" "cartman13" "cartman08" "cartman06" ];
      rzrl1 = [ "kyle04" "kenny03" "kenny02" "cartman04" "cartman05" ];
      whq = [ "barbrady01" "cartman00" "kyle03" "terri" "edna" "hibbert" "bob" "lou" ];
      # Location-independent NTP servers from the global public pool.
      standalone = [ "0.pool.ntp.org" "1.pool.ntp.org" "2.pool.ntp.org" ];
    };

    # Generally allow DHCP?
    flyingcircus.static.allowDHCP = {
      standalone = true;
      vagrant = true;
    };
    ids.uids = {
      # Sames as upstream/master, but not yet merged
      kibana = 211;

      # Our custom services
      sensuserver = 31001;
      sensuapi = 31002;
      uchiwa = 31003;
      sensuclient = 31004;
      powerdns = 31005;
      graylog = 31006;
    };

    ids.gids = {
      users = 100;
      # The generic 'service' GID is different from Gentoo.
      # But 101 is already used in NixOS.
      service = 900;

      # Our permissions
      login = 500;
      code = 501;
      stats = 502;
      sudo-srv = 503;
      manager = 504;

      # Our custom services
      sensuserver = 31001;
      sensuapi = 31002;
      uchiwa = 31003;
      sensuclient = 31004;
    };

  };
}
