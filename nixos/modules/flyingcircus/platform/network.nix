{ config, lib, pkgs, ... }:

with builtins;

let
  cfg = config.flyingcircus;

  fclib = import ../lib;

  # generally use DHCP in the current location?
  allowDHCP = location:
    if hasAttr location cfg.static.allowDHCP
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

  # Adapted 'ip' command which says what it is doing and ignores errno 2 (file
  # exists) to make it idempotent.
  relaxedIp = pkgs.writeScriptBin "ip" ''
    #! ${pkgs.stdenv.shell} -e
    echo ip "$@"
    rc=0
    ${pkgs.iproute}/bin/ip "$@" || rc=$?
    if ((rc == 2)); then
      exit 0
    else
      exit $rc
    fi
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
        default =
          (lib.hasAttrByPath ["parameters" "interfaces"] cfg.enc) &&
          (lib.hasAttrByPath ["parameters" "location"] cfg.enc);
        description = "Enable policy routing?";
      };
    };

  };

  config = rec {
    environment.etc."iproute2/rt_tables".text = rt_tables;

    services.udev.extraRules =
    if cfg.network.policy_routing.enable then
      lib.concatMapStrings
        (vlan:
          let mac = lib.toLower cfg.enc.parameters.interfaces.${vlan}.mac;
          in ''
            KERNEL=="eth*", ATTR{address}=="${mac}", NAME="eth${vlan}"
          '')
        (attrNames cfg.enc.parameters.interfaces)
    else
      (lib.concatStrings
        (lib.mapAttrsToList (n: vlan: ''
          KERNEL=="eth*", ATTR{address}=="02:00:00:${
            fclib.byteToHex (lib.toInt n)}:??:??", NAME="eth${vlan}"
        '') cfg.static.vlans)
      );

    networking.domain = "gocept.net";

    networking.nameservers =
      if (lib.hasAttrByPath [ "parameters" "location" ] cfg.enc) &&
         (hasAttr cfg.enc.parameters.location cfg.static.nameservers)
      then cfg.static.nameservers.${cfg.enc.parameters.location}
      else [];
    networking.resolvconfOptions = "ndots:1 timeout:1 attempts:4 rotate";

    networking.search =
      if lib.hasAttrByPath [ "parameters" "location" ] cfg.enc then
        [ "${cfg.enc.parameters.location}.${networking.domain}"
          networking.domain
        ]
      else [];

    # data structure for all configured interfaces with their IP addresses:
    # { ethfe = { ... }; ethsrv = { }; ... }
    networking.interfaces =
      if lib.hasAttrByPath [ "parameters" "interfaces" ] cfg.enc
      then lib.mapAttrs'
        (vlan: iface:
          lib.nameValuePair
            "eth${vlan}"
            (fclib.interfaceConfig iface.networks // { useDHCP = false; }))
        cfg.enc.parameters.interfaces
      else {};

    systemd.services =
      if cfg.network.policy_routing.enable then
        listToAttrs
          (map
            (vlan: lib.nameValuePair
              "network-policyrouting-eth${vlan}"
              {
                requires = [ "network-addresses-eth${vlan}.service" ];
                after = [ "network-addresses-eth${vlan}.service" ];
                wantedBy = [ "network-interfaces.target" ];
                bindsTo = [ "sys-subsystem-net-devices-eth${vlan}.device" ];
                description = "Policy routing for eth${vlan}";
                path = [ relaxedIp ];
                script = fclib.policyRouting {
                  vlan = "${vlan}";
                  encInterface = cfg.enc.parameters.interfaces.${vlan};
                };
                preStop = fclib.policyRouting {
                  vlan = "${vlan}";
                  encInterface = cfg.enc.parameters.interfaces.${vlan};
                  action = "stop";
                };
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                };
              })
            (attrNames cfg.enc.parameters.interfaces)) //
        listToAttrs
          (map
            (vlan:
            let
              mac = lib.toLower cfg.enc.parameters.interfaces.${vlan}.mac;
            in
            lib.nameValuePair
              "network-disable-ipv6-autoconf-eth${vlan}"
              {
                before = [ "network-pre.target" ];
                wantedBy = [ "network-pre.target" ];
                description = "Turn off IPv6 SLAAC on eth${vlan}";
                script = ''
                  ${pkgs.nettools}/bin/nameif eth${vlan} ${mac}
                  echo 0 >/proc/sys/net/ipv6/conf/eth${vlan}/autoconf
                '';
                serviceConfig = { Type = "oneshot"; };
              })
            (attrNames cfg.enc.parameters.interfaces))
      else {};

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

    # DHCP settings: never do IPv4ll and don't use it at all if PR is enabled
    networking.useDHCP =
      !cfg.network.policy_routing.enable ||
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
  };
}
