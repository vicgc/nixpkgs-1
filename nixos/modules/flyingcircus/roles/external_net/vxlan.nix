# Gateway to external network via VxLAN tunnel.

{ config, lib, pkgs, ... }:

with builtins;

let
  fclib = import ../../lib;

  cfg = config.flyingcircus;
  parameters = lib.attrByPath [ "enc" "parameters" ] {} cfg;
  interfaces = lib.attrByPath [ "interfaces" ] {} parameters;
  resource_group = lib.attrByPath [ "resource_group" ] null parameters;
  net4 = cfg.roles.external_net.vxlan4;
  net6 = cfg.roles.external_net.vxlan6;
  dev = "nx0";
  port = 8472;

  exampleConfig = ''
    {
      "local": "2001:db8:62::118d",
      "remote": "2001:db0:ff::30d",
      "vid": 2,
      "mtu": 1430
    }
  '';

  localConfig = (fromJSON
    (fclib.configFromFile /etc/local/vxlan/config.json "{}"));

    # Compute all necessary parameters with Python and funnel them into Nix
    # via JSON marshalling. You could call this a hack.
    params = fromJSON (readFile (
      pkgs.stdenv.mkDerivation {
        name = "external-network-params.json";
        # expects net4 and net6 as command line arguments, returns a JSON
        # containg all kinds of VxLAN/dnsmasq addresses/networks
        script = ''
          import json
          import ipaddress
          import sys
          net4, net6 = sys.argv[1:]
          ip4 = ipaddress.ip_network(net4)
          ip6 = ipaddress.ip_network(net6)
          print(json.dumps({
            'gw4': '{}/{}'.format(ip4[1], ip4.prefixlen),
            'gw6': '{}/{}'.format(ip6[1], ip6.prefixlen),
            'dhcp': (str(ip4[2]), str(ip4[-1])),
          }))
        '';
        passAsFile = [ "script" ];
        buildCommand = ''
          ${pkgs.python34.interpreter} $scriptPath ${net4} ${net6} > $out
        '';
      }).out);

    mtu = lib.attrByPath [ "mtu" ] 1430 localConfig;

    domain =
      if resource_group != null
      then "${resource_group}.fcio.net"
      else "local";

    dnsmasqConf = ''
      dhcp-authoritative
      dhcp-fqdn
      dhcp-leasefile=/var/lib/dnsmasq.leases
      dhcp-option=option6:dns-server,[::]
      dhcp-option=option6:ntp-server,[::]
      dhcp-option=option:dns-server,0.0.0.0
      dhcp-option=option:mtu,${toString mtu}
      dhcp-option=option:ntp-server,0.0.0.0
      dhcp-range=::,constructor:${dev},ra-names
      dhcp-range=${lib.concatStringsSep "," params.dhcp},4h
      domain=ext.${domain}
      domain-needed
      interface=${dev}
      local-ttl=60
    '';

in
{
  options = {
    flyingcircus.roles.vxlan.gateway = lib.mkEnableOption { };
  };

  config = lib.mkIf (cfg.roles.vxlan.gateway) (
    let
      additionalOptions = {
        services.dnsmasq = {
          enable = true;
          extraConfig = dnsmasqConf;
        };

        services.chrony.extraConfig = ''
          allow ${net4}
          allow ${net6}
        '';

        # See openvpn.nix for additional firewall rules
        networking.firewall.allowedUDPPorts = [ 53 67 68 123 port ];
      };

    in
    lib.optionalAttrs (localConfig != {}) (
      import ../../services/vxlan.nix {
        inherit (localConfig) vid local remote;
        inherit (params) gw4 gw6;
        inherit dev mtu lib pkgs;
      } //
      additionalOptions
    ) //
    {
      environment.etc."local/vxlan/config.json.example".text = exampleConfig;
      environment.etc."local/vxlan/README".text = readFile ./README.vxlan;
    }
  );
}
