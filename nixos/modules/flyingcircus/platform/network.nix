{ config, lib, ... }:

with builtins;

let
  cfg = config.flyingcircus;

  fclib = import ../lib;

  _ip_interface_configuration = networks: network:
      map (
        ip_address: {
          address = ip_address;
          prefixLength = fclib.prefixLength network;
        })
       (getAttr network networks);

  get_ip_configuration = version_filter: networks:
    lib.concatMap
      (_ip_interface_configuration networks)
      (filter version_filter (attrNames networks));


  get_interface_ips = networks:
    { ip4 = get_ip_configuration fclib.isIp4 networks;
      ip6 = get_ip_configuration fclib.isIp6 networks;
    };

  allow_dhcp = config.flyingcircus.static.allowDHCP.${config.flyingcircus.enc.parameters.location};

  get_interface_configuration = interfaces: interface_name:
    { name = "eth${interface_name}";
      value = (get_interface_ips (getAttr interface_name interfaces).networks) //
              { useDHCP = if interface_name == "srv" then allow_dhcp else false; };
    };

  get_network_configuration = interfaces:
    listToAttrs
      (map
       (get_interface_configuration interfaces)
       (attrNames interfaces));

  # Policy routing

  routing_priorities = {
    fe = 200;
    srv = 300;
  };

  get_policy_routing_for_interface = interfaces: interface_name:
    map (network:
    let
      ifconfig = interfaces.${interface_name};
      addresses = ifconfig.networks.${network};
    in
    {
      priority =
        if builtins.length addresses == 0
        then 900
        else lib.attrByPath [ interface_name ] 1000 routing_priorities;
      network = network;
      interface = interface_name;
      gateway = ifconfig.gateways.${network};
      addresses = addresses;
      family = if (fclib.isIp4 network) then "4" else "6";
    }) (attrNames interfaces.${interface_name}.gateways);


  # Those policy routing rules ensure that we can run multiple IP networks
  # on the same ethernet segment. We will still use the router but we avoid,
  # for example, that we send out to an SRV network over the FE interface
  # which may confuse the sender trying to reply to us on the FE interface
  # or even filtering the traffic when the other interface has a shared
  # network.
  #
  # The address rules ensure that we send out over the interface that belongs
  # to the connection that a packet belongs to, i.e. established flows.
  # (Address rules only apply to networks we have an address for.)
  #
  # The network rules ensure that we packets over the best interface where
  # the target network is reachable if we haven't decided the originating
  # address, yet.
  # (Network rules apply for all networks on the segment, even if we do not
  # have an address for it.)
  policy_routing_rules = ruleset:
    let
      rs = ruleset;
      ip = "ip -${rs.family}";
      address_rules = if (builtins.length rs.addresses != 0) then
        (lib.concatMapStrings
          (address:
            ''
              ${ip} rule add priority ${toString (rs.priority)} from ${address} lookup ${rs.interface}
            '')
          rs.addresses) else "";
      defroute = "default via ${rs.gateway} dev eth${rs.interface}";
      gateway_rules = if (builtins.length rs.addresses != 0) then
        ''
          ${ip} route add ${defroute} table ${rs.interface} || true
          ${ip} route add ${defroute} metric ${toString rs.priority} || true
        '' else "";
    in
    ''
      # ${rs.interface}/IPv${rs.family}
      ${ip} rule add priority ${
        toString rs.priority} from all to ${rs.network} lookup ${
        rs.interface}
      ${ip} route add ${rs.network} dev eth${rs.interface} table ${rs.interface} || true
      ${address_rules}
      ${gateway_rules}
    '';

  get_policy_routing = interfaces:
    map
      policy_routing_rules
        (lib.concatMap
          (get_policy_routing_for_interface interfaces)
          (attrNames interfaces));

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
in

{

  options = {

    flyingcircus.network.policy_routing = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
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
      then ["${cfg.enc.parameters.location}.gocept.net"
            "gocept.net"]
      else [];

    # data structure for all configured interfaces with their IP addresses:
    # { ethfe = { ... }; ethsrv = { }; ... }
    networking.interfaces =
      if lib.hasAttrByPath ["parameters" "interfaces"] cfg.enc
      then get_network_configuration cfg.enc.parameters.interfaces
      else {};

    networking.localCommands =
      if
        cfg.network.policy_routing.enable &&
        lib.hasAttrByPath ["parameters" "interfaces"] cfg.enc
      then
        ''
          ip -4 rule flush
          ip -4 rule add priority 32766 lookup main
          ip -4 rule add priority 32767 lookup default

          ip -6 rule flush
          ip -6 rule add priority 32766 lookup main
          ip -6 rule add priority 32767 lookup default

          ${lib.concatStrings (get_policy_routing cfg.enc.parameters.interfaces)}
        ''
        else "";


    # FC: allow srv access for machines in the same RG
    # I'd like to move this into our firewall module but for some reason the
    # access to networking.interfaces then fails. :/
    networking.firewall.extraCommands =
      let
        addrs_srv = map (elem: elem.ip) cfg.enc_addresses.srv;
        addrs_fe = map (elem: elem.ip) cfg.enc_addresses.fe;
        rule = eth: a: ''
          ${fclib.iptables a} -A nixos-fw -i ${eth} -s ${fclib.stripNetmask a
            } -j nixos-fw-accept
        '';
        rules_for = eth: addrs:
          (lib.concatMapStrings
            (rule eth)
            addrs);
        rules_srv = lib.optionalString
          (lib.hasAttr "ethsrv" networking.interfaces)
          (rules_for "ethsrv" addrs_srv);
        rules_fe = lib.optionalString
          (lib.hasAttr "ethfe" networking.interfaces)
          (rules_for "ethfe" addrs_fe);
        rules_srv_to_fe = lib.optionalString
          (lib.hasAttr "ethfe" networking.interfaces)
          (rules_for "ethfe" addrs_srv);
      in ''
        # Accept traffic within the same resource group.
        ${rules_srv}
        ${rules_fe}
        # Accept traffic from other SRV to our FE
        ${rules_srv_to_fe}
      '';

    # DHCP settings: never use implicitly, never do IPv4ll
    networking.useDHCP = false;
    networking.dhcpcd.extraConfig = ''
      # IPv4ll gets in the way if we really do not want
      # an IPv4 address on some interfaces.
      noipv4ll
    '';

    boot.kernel.sysctl = {
      "net.ipv4.ip_local_port_range" = "32768 60999";
      "net.ipv4.ip_local_reserved_ports" = "61000-61999";
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
    };

  };
}
