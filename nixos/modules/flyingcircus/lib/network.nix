/*
 * generic networking functions for use in all of the flyingcircus Nix stuff
 */

{ lib }:

rec {
  stripNetmask = cidr: builtins.elemAt (lib.splitString "/" cidr) 0;

  prefixLength = cidr: lib.toInt (builtins.elemAt (lib.splitString "/" cidr) 1);

  isIp4 = cidr: builtins.length (lib.splitString "." cidr) == 4;

  isIp6 = cidr: builtins.length (lib.splitString ":" cidr) > 1;

  # choose the correct iptables version for addr
  iptables = addr: if isIp4 addr then "iptables" else "ip6tables";

  # choose correct "ip" invocation depending on addr
  ip' = addr: if isIp4 addr then "ip -4" else "ip -6";

  # list IP addresses for service configuration (e.g. nginx)
  listenAddresses = config: interface:
    if interface == "lo"
    # lo isn't part of the enc. Hard code it here.
    then [ "127.0.0.1" "::1" ]
    else
      if builtins.hasAttr interface config.networking.interfaces
      then
        let
          interface_config = builtins.getAttr interface config.networking.interfaces;
        in
          (map (addr: addr.address) interface_config.ip4) ++
          (map (addr: addr.address) interface_config.ip6)
      else [];

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
      (builtins.attrNames relevantNetworks);

  # ENC networks to NixOS option for both address families
  interfaceConfig = useDHCP: networks:
    { inherit useDHCP;
      ip4 = ipAddressesOption isIp4 networks;
      ip6 = ipAddressesOption isIp6 networks;
    };

  interfaceAddresses = networks:
    let
      prefix = cidr: builtins.elemAt (lib.splitString "/" cidr) 1;
      addrsWithNetmask = net: addrs:
        map (a: a + "/" + (prefix net)) addrs;
    in lib.concatLists (lib.mapAttrsToList addrsWithNetmask networks);

  # IP policy rules
  ipRules = vlan: encInterfaces:
    let
      allAddresses = interfaceAddresses encInterfaces.${vlan}.networks;
      fromRules = lib.concatMapStringsSep "\n"
        (a:  "${ip' a} rule add from ${a} table ${vlan}")
        allAddresses;
      afPresent = afPred: cidrs: lib.any afPred cidrs;
      # all networks of a given AF if at least any address of this AF is present
      maskedNetworks = afPred:
        if (afPresent afPred allAddresses)
        then builtins.filter
          afPred
          (lib.attrNames encInterfaces.${vlan}.networks)
        else [];
      toNetworks = afPredicates:
        lib.concatMap maskedNetworks afPredicates;
      toRules = lib.concatMapStringsSep "\n"
        (n: "${ip' n} rule add to ${n} table ${vlan}")
        (toNetworks [ isIp4 isIp6 ]);
    in
    ''
    # IP policy rules for ${vlan}
    ${fromRules}
    ${toRules}
    '';
}
