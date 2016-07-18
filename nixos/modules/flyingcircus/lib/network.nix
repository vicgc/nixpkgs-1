/*
 * generic networking functions for use in all of the flyingcircus Nix stuff
 */

{ lib }:

with builtins;
rec {
  stripNetmask = cidr: elemAt (lib.splitString "/" cidr) 0;

  prefixLength = cidr: lib.toInt (elemAt (lib.splitString "/" cidr) 1);

  isIp4 = cidr: length (lib.splitString "." cidr) == 4;

  isIp6 = cidr: length (lib.splitString ":" cidr) > 1;

  # choose the correct iptables version for addr
  iptables = addr: if isIp4 addr then "iptables" else "ip6tables";

  # choose correct "ip" invocation depending on addr
  ip' = addr: "ip " + (if isIp4 addr then "-4" else "-6");

  # list IP addresses for service configuration (e.g. nginx)
  listenAddresses = config: interface:
    if interface == "lo"
    # lo isn't part of the enc. Hard code it here.
    then [ "127.0.0.1" "::1" ]
    else
      if hasAttr interface config.networking.interfaces
      then
        let
          interface_config = getAttr interface config.networking.interfaces;
        in
          (map (addr: addr.address) interface_config.ip4) ++
          (map (addr: addr.address) interface_config.ip6)
      else [];

  /*
   * policy routing
   */

  dev = vlan: bridged: if bridged then "br${vlan}" else "eth${vlan}";

  # VLANS with prio < 100 are generally routable to the outside.
  routingPriorities = {
    fe = 50;
    srv = 60;
    mgm = 90;
  };

  routingPriority = vlan:
    if hasAttr vlan routingPriorities
    then routingPriorities.${vlan}
    else 100;

  # transforms ENC "networks" data structure into an NixOS "interface" option
  # for all nets that satisfy `pred`
  # {
  #   "172.30.3.0/24" = [ "172.30.3.66" ... ];
  #   ...;
  # }
  # =>
  # [ { address = "172.30.3.66"; prefixLength = "24"; } ... ];
  ipAddressesOption = pred: networks:
    let
      transformAddrs = net: addrs:
        map
          (a: { address = a; prefixLength = prefixLength net; })
          addrs;
      relevantNetworks = lib.filterAttrs (net: val: pred net) networks;
    in
    lib.concatMap
      (n: transformAddrs n networks.${n})
      (attrNames relevantNetworks);

  # ENC networks to NixOS option for both address families
  interfaceConfig =
    { networks
    , useDHCP ? false }:
    { inherit useDHCP;
      ip4 = ipAddressesOption isIp4 networks;
      ip6 = ipAddressesOption isIp6 networks;
    };

  # Collects a complete list of configured addresses from all networks.
  # Each address is suffixed with the netmask from its network.
  allInterfaceAddresses = networks:
    let
      prefix = cidr: elemAt (lib.splitString "/" cidr) 1;
      addrsWithNetmask = net: addrs:
        map (a: a + "/" + (prefix net)) addrs;
    in lib.concatLists (lib.mapAttrsToList addrsWithNetmask networks);

  # List of nets (CIDR) that have at least one address present which satisfies
  # `predicate`.
  networksWithAtLeastOneAddress = encNetworks: predicate:
  let
    hasAtAll = pred: cidrs: lib.any pred cidrs;
  in
    if (hasAtAll predicate (allInterfaceAddresses encNetworks))
    then filter predicate (lib.attrNames encNetworks)
    else [];

  filteredNetworks = encNetworks: predicates:
    lib.concatMap (networksWithAtLeastOneAddress encNetworks) predicates;

  # IP policy rules for a single VLAN.
  # Expects a VLAN name and an ENC "interfaces" data structure. Expected keys:
  # mac, networks, bridged, gateways.
  ipRules = vlan: encInterface: verb:
    let
      prio = routingPriority vlan;
      common = "table ${vlan} priority ${toString prio}";
      fromRules = lib.concatMapStringsSep "\n"
        (a: "${ip' a} rule ${verb} from ${a} ${common}")
        (allInterfaceAddresses encInterface.networks);
      toRules = lib.concatMapStringsSep "\n"
        (n: "${ip' n} rule ${verb} to ${n} ${common}")
        (filteredNetworks encInterface.networks [ isIp4 isIp6 ]);
    in
    "\n# policy rules for ${vlan}\n${fromRules}\n${toRules}\n";

  ipRoutes = vlan: encInterface: verb:
    let
      prio = routingPriority vlan;
      dev' = dev vlan encInterface.bridged;

      networkRoutes = afPredicates:
        map
          (net: {
            inherit net;
            src = elemAt encInterface.networks.${net} 0;
          })
          (filteredNetworks encInterface.networks afPredicates);
      networkRoutesStr = lib.concatMapStrings
        ({net, src}: ''
          ${ip' net} route ${verb} ${net} dev ${dev'} metric ${toString prio} src ${src} table ${vlan}
        '')
        (networkRoutes [ isIp4 isIp6 ]);

      # Builds a list of default gateways from a (filtered) list of networks in
      # CIDR form.
      gateways = nets:
        foldl'
          (gws: cidr:
            if hasAttr cidr encInterface.networks
            then gws ++ [encInterface.gateways.${cidr}]
            else gws)
          []
          nets;

      gatewayRoutesStr = lib.optionalString
        (100 > routingPriority vlan)
        (lib.concatMapStrings
          (gw:
          ''
            ${ip' gw} route ${verb} default via ${gw} dev ${dev'} metric ${toString prio}
            ${ip' gw} route ${verb} default via ${gw} dev ${dev'} metric ${toString prio} table ${vlan}
          '')
          (gateways (filteredNetworks encInterface.networks [ isIp4 isIp6])));
    in
    "\n# routes for ${vlan}\n${networkRoutesStr}${gatewayRoutesStr}";

    policyRouting =
      { vlan
      , encInterface
      , action ? "start"  # or "stop"
      }:
      if action == "start"
      then ''
        set -v
        ${ipRules vlan encInterface "add"}
        ${ipRoutes vlan encInterface "append"}
      '' else ''
        set +e
        set -v
        ${ipRoutes vlan encInterface "del"}
        ${ipRules vlan encInterface "del"}
      '';

}
