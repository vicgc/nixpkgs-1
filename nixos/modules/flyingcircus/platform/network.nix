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

  interfaces = lib.attrByPath [ "parameters" "interfaces" ] {} cfg.enc;
  location = lib.attrByPath [ "parameters" "location" ] "standalone" cfg.enc;

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
        default = !(pathExists "/etc/local/simplerouting");
        description = ''
          Enable policy routing? Touch /etc/local/simplerouting to turn policy
          routing off.
        '';
      };
    };

  };

  config = rec {
    environment.etc."iproute2/rt_tables".text = rt_tables;

    services.udev.extraRules =
      lib.concatMapStrings
        (vlan:
          let
            fallback = "02:00:00:${fclib.byteToHex (lib.toInt n)}:??:??";
            mac = lib.toLower
              (lib.attrByPath [ vlan "mac" ] fallback interfaces);
          in ''
            KERNEL=="eth*", ATTR{address}=="${mac}", NAME="eth${vlan}"
          '')
        (attrNames interfaces);

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
      lib.mapAttrs'
        (vlan: iface:
          lib.nameValuePair
            "eth${vlan}"
            (fclib.interfaceConfig iface.networks // { useDHCP = false; }))
        interfaces;

    systemd.services =
      let startStopScript = if cfg.network.policy_routing.enable
        then fclib.policyRouting
        else fclib.simpleRouting;
      in
      (listToAttrs
        (map (vlan:
          let mac = lib.toLower interfaces.${vlan}.mac;
          in
          lib.nameValuePair
            "network-no-autoconf-eth${vlan}"
            rec {
              description = "Disable IPv6 SLAAC (autconf) on eth${vlan}";
              wantedBy =
                [ "network-pre.target"
                  "network-addresses-eth${vlan}.service"
                ];
              before = wantedBy;
              script = ''
                ${pkgs.nettools}/bin/nameif eth${vlan} ${mac}
                echo 0 >/proc/sys/net/ipv6/conf/eth${vlan}/autoconf
              '';
              preStop = ''
                echo 1 >/proc/sys/net/ipv6/conf/eth${vlan}/autoconf
              '';
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
            })
          (attrNames interfaces)))
      //
      listToAttrs
        (map
          (vlan: lib.nameValuePair
            "network-routing-eth${vlan}"
            rec {
              description = "Custom IP routing for eth${vlan}";
              requires = [ "network-addresses-eth${vlan}.service" ];
              after = requires;
              before = [ "network-local-commands.service" ];
              wantedBy = [ "network-interfaces.target" ];
              bindsTo = [ "sys-subsystem-net-devices-eth${vlan}.device" ];
              path = [ relaxedIp ];
              script = startStopScript {
                vlan = "${vlan}";
                encInterface = interfaces.${vlan};
              };
              preStop = startStopScript {
                vlan = "${vlan}";
                encInterface = interfaces.${vlan};
                action = "stop";
              };
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
            })
          (attrNames interfaces));

    # firewall configuration: generic options
    networking.firewall.allowPing = true;
    networking.firewall.rejectPackets = true;

    # DHCP settings: never do IPv4ll and don't use DHCP if there is explicit
    # network configuration present
    networking.useDHCP =
      (interfaces == {}) || (allowDHCP cfg.enc.parameters.location);
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
      "net.ipv6.conf.all.autoconf" = 0;
      "net.ipv6.conf.default.autoconf" = 0;
    };
  };
}
