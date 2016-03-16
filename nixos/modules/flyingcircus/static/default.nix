{ lib, ... }:
with lib;
{
  options = {

    flyingcircus.static = mkOption {
      type = types.attrsOf types.attrs;
      default = { };
      description = "Static lookup tables for site-specfic information";
    };

  };

  config = {
    flyingcircus.static.vlans = {
      "1" = "mgm";
      "2" = "fe";
      "3" = "srv";
      "4" = "sto";
      "5" = "ws";
      "6" = "tr";
      "7" = "gue";
      "8" = "stb";
      "14" = "tr2";
      "15" = "gocept";
      "16" = "fe2";
      "17" = "srv2";
      "18" = "tr3";
    };

    flyingcircus.static.nameservers = {
      # ns.$location.gocept.net, ns2.$location.gocept.net
      # We are currently not using IPv6 resolvers as we have seen obscure bugs
      # when enabling them, like weird search path confusion that results in
      # arbitrary negative responses, combined with the rotate flag.
      #
      # This seems to be https://sourceware.org/bugzilla/show_bug.cgi?id=13028
      # which is fixed in glibc 2.22 which is included in NixOS 16.03.
      dev = ["172.30.3.10" "172.20.2.38"];
      rzob = ["195.62.125.5" "195.62.125.135"];
      rzrl1 = ["172.24.32.3" "172.24.48.4"];
      whq = ["212.122.41.143" "212.122.41.169"];
    };
  };
}
