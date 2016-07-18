{ config, lib, pkgs, ... }:

with builtins;

let
  cfg = config.flyingcircus;

  fclib = import ../lib;

  # generally use DHCP in the current location?
  allowDHCP = location:
    if builtins.hasAttr location cfg.static.allowDHCP
    then cfg.static.allowDHCP.${cfg.enc.parameters.location}
    else false;

  # Policy routing

  rt_tables = ''
    # reserved values
    #
    255 local
    254 main
    253 default
    0 unspec
    #
    # local
    #
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (n : vlan : "${n} ${vlan}")
      cfg.static.vlans
    )}
    '';

  # add srv addresses from my own resource group to /etc/hosts
  hostsFromEncAddresses = enc_addresses:
    let
      recordToEtcHostsLine = r:
        "${fclib.stripNetmask r.ip} ${r.name}.${config.networking.domain} ${r.name}";
    in
      # always mention IPv6 addresses first to get predictable behaviour
      lib.concatMapStringsSep "\n" recordToEtcHostsLine
        ((filter (a: fclib.isIp6 a.ip) enc_addresses) ++
         (filter (a: fclib.isIp4 a.ip) enc_addresses));

in
{
  options = {

    flyingcircus.network.policy_routing = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = lib.hasAttrByPath ["parameters" "interfaces"] cfg.enc;
        description = "Enable policy routing?";
      };
    };

  };

  config = rec {
    environment.etc."iproute2/rt_tables".text = rt_tables;

    services.udev.extraRules = (lib.concatStrings
      (lib.mapAttrsToList (n : vlan : ''
        KERNEL=="eth*", ATTR{address}=="02:00:00:${
          fclib.byteToHex (lib.toInt n)}:??:??", NAME="eth${vlan}"
      '') cfg.static.vlans)
    );

    networking.domain = "gocept.net";

    # Only set nameserver if there is an enc set.
    networking.nameservers =
      if lib.hasAttrByPath ["parameters" "location"] cfg.enc
      then
        if hasAttr cfg.enc.parameters.location cfg.static.nameservers
        then cfg.static.nameservers.${cfg.enc.parameters.location}
        else []
      else [];
    networking.resolvconfOptions = "ndots:1 timeout:1 attempts:4 rotate";

    # If there is no enc data, we are probably not on FC platform.
    networking.search =
      if lib.hasAttrByPath ["parameters" "location"] cfg.enc
      then
        [ "${cfg.enc.parameters.location}.${networking.domain}"
          networking.domain
        ]
      else [];

    # data structure for all configured interfaces with their IP addresses:
    # { ethfe = { ... }; ethsrv = { }; ... }
    networking.interfaces =
      if lib.hasAttrByPath ["parameters" "interfaces"] cfg.enc
      then lib.mapAttrs'
        (vlan: iface:
          let
            useDHCP = (vlan == "srv") &&
              (lib.hasAttrByPath [ "parameters" "location" ] cfg.enc) &&
              (allowDHCP cfg.enc.parameters.location);
            networks = iface.networks;
          in
          lib.nameValuePair
            "eth${vlan}"
            (fclib.interfaceConfig { inherit useDHCP networks; }))
        (cfg.enc.parameters.interfaces)
      else {};

    # networking.localCommands =
    #   lib.optionalString
    #     (cfg.network.policy_routing.enable)
    #     (''
    #       set -v
    #     '' + lib.concatMapStrings
    #       (vlan: fclib.policyRouting vlan cfg.enc.parameters.interfaces.${vlan})
    #       (attrNames cfg.enc.parameters.interfaces));
    systemd.services.network-policyrouting-ethsrv = {
      requires = [ "network-addresses-ethsrv.service" ];
      after = [ "network-addresses-ethsrv.service" ];
      wantedBy = [ "network-interfaces.target" ];
      bindsTo = [ "sys-subsystem-net-devices-ethsrv.device" ];
      description = "Policy routing for ethsrv";
      path = [ pkgs.iproute ];
      script = fclib.policyRouting {
        vlan = "srv";
        encInterface = cfg.enc.parameters.interfaces.srv;
      };
      unitConfig = { Type = "oneshot"; };
    };

    # firewall configuration: generic options
    networking.firewall.allowPing = true;
    networking.firewall.rejectPackets = true;

    # allow srv access for machines in the same RG
    networking.firewall.extraCommands =
      let
        addrs = map (elem: elem.ip) cfg.enc_addresses.srv;
        rules = lib.optionalString
          (lib.hasAttr "ethsrv" networking.interfaces)
          (lib.concatMapStringsSep "\n"
            (a: "${fclib.iptables a} -A nixos-fw -i ethsrv -s ${fclib.stripNetmask a} -j nixos-fw-accept")
            addrs);
      in
      "# Accept traffic within the same resource group.\n${rules}";

    # DHCP settings: never do IPv4ll
    networking.useDHCP =
      (lib.hasAttrByPath [ "parameters" "location" ] cfg.enc) &&
      (allowDHCP cfg.enc.parameters.location);
    networking.dhcpcd.extraConfig = ''
      # IPv4ll gets in the way if we really do not want
      # an IPv4 address on some interfaces.
      noipv4ll
    '';

    networking.extraHosts = lib.optionalString
      (cfg.enc_addresses.srv != [])
      (hostsFromEncAddresses cfg.enc_addresses.srv);

    boot.kernel.sysctl = {
      "net.ipv4.ip_local_port_range" = "32768 60999";
      "net.ipv4.ip_local_reserved_ports" = "61000-61999";
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv6.conf.all.autoconf" = 0;
      "net.ipv6.conf.default.autoconf" = 0;
    };
    # //
    # lib.listToAttrs
    #   (lib.foldl'
    #     (settings: vlan: settings ++ [
    #       (lib.nameValuePair "net.ipv6.conf.eth${vlan}.autoconf" 0)
    #     ])
    #     []
    #     (lib.attrNames cfg.enc.parameters.interfaces));
  };
}
