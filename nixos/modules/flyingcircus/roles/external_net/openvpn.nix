{ config, lib, pkgs, stdenv, ... }:

with builtins;

let
  fclib = import ../../lib;
  decomposeCIDR = fclib.decomposeCIDR pkgs;
  cfg = config.flyingcircus;
  parameters = lib.attrByPath [ "enc" "parameters" ] {} cfg;
  interfaces = lib.attrByPath [ "interfaces" ] {} parameters;
  location = lib.attrByPath [ "location" ] null parameters;
  resource_group = lib.attrByPath [ "resource_group" ] null parameters;
  domain = config.networking.domain;
  id16bit = fclib.mod (lib.attrByPath [ "id" ] 0 parameters) 65536;

  defaultAccessNets = ''
    {
      "ipv4": "10.70.67.0/24",
      "ipv6": "fd3e:65c4:fc10:${fclib.toHex id16bit}::/64",
      "extraroutes": []
    }
  '';

  ovpn = "${pki.caDir}/${frontendName}.ovpn";

  #
  # packages
  #
  inherit (pkgs) openvpn;
  easyrsa = pkgs.easyrsa3;
  pki = pkgs.callPackage ./generate-pki.nix {
    inherit easyrsa openvpn resource_group location;
  };

  #
  # addresses
  #
  # attrset of those fe addresses that have a reverse
  feReverses =
    # fake attrset from listenAddresses: { "addr" = null; ... }
    let feAddrSet =
      lib.genAttrs (fclib.listenAddresses config "ethfe") (x: null);
    in
    intersectAttrs feAddrSet (lib.attrByPath [ "reverses" ] {} parameters);

  # pick a suitable DNS name for client config
  frontendName =
    if feReverses != {}
    then fclib.normalizeDomain domain (head (attrValues feReverses))
    else
      if location != null
      then "${config.networking.hostName}.fe.${location}.${domain}"
      else "localhost";

  allNetworks = lib.zipAttrs (lib.catAttrs "networks" (attrValues interfaces));

  extraroutes = lib.attrByPath [ "extraroutes" ] [] accessNets;

  pushRoutes4 =
    lib.concatMapStringsSep "\n"
      (cidr: "push \"route ${decomposeCIDR cidr}\"")
      (filter fclib.isIp4 (attrNames allNetworks ++ extraroutes));

  pushRoutes6 =
    lib.concatMapStringsSep "\n"
      (cidr: "push \"route-ipv6 ${cidr}\"")
      (filter fclib.isIp6 (attrNames allNetworks ++ extraroutes));

  # Caution: we also deliver FE addresses here, so these should be included in
  # the pushed routes.
  pushNameservers = lib.concatMapStringsSep "\n"
    (a: "push \"dhcp-option DNS ${a}\"")
    (lib.attrByPath [ (toString location) ] "" cfg.static.nameservers);

  #
  # server
  #
  accessNets = (fromJSON
    (fclib.configFromFile /etc/local/openvpn/networks.json defaultAccessNets));

  serverAddrs = ''
    server ${decomposeCIDR accessNets.ipv4}
    server-ipv6 ${accessNets.ipv6}
  '';

  serverConfig = ''
    # OpenVPN server config for ${frontendName}
    ${serverAddrs}

    port 1194
    proto udp6
    dev tun
    multihome

    persist-key
    persist-tun
    duplicate-cn
    ca ${pki.caCrt}
    cert ${pki.serverCrt}
    key ${pki.serverKey}
    dh ${pki.dh}
    tls-auth ${pki.ta} 0

    keepalive 10 120
    plugin ${openvpn}/lib/openvpn/plugins/openvpn-plugin-auth-pam.so openvpn

    comp-lzo
    user nobody
    group nogroup

    push "redirect-private"
    ${pushRoutes4}
    ${pushRoutes6}
    push "dhcp-option DOMAIN ${domain}"
    ${pushNameservers}
  '';

  #
  # client config
  #
  ovpnTemplate = pkgs.writeText "client.ovpn-template" ''
    #viscosity name ${frontendName}

    client
    dev tun

    proto udp
    remote ${frontendName}
    nobind
    persist-key
    persist-tun
    comp-lzo
    verb 3
    remote-cert-tls server
    auth-user-pass

    ca [inline]
    cert [inline]
    key [inline]
    tls-auth [inline] 1

    <ca>
    @caCrt@
    </ca>

    <cert>
    @clientCrt@
    </cert>

    <key>
    @clientKey@
    </key>

    <tls-auth>
    @ta@
    </tls-auth>
  '';

in
{
  options = {
    flyingcircus.roles.openvpn.enable = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.roles.openvpn.enable {

    environment.systemPackages = [ pkgs.easyrsa3 ];

    environment.etc = {
      "local/openvpn/${frontendName}.ovpn".source = ovpn;
      "local/openvpn/networks.json.example".text = defaultAccessNets;
      "local/openvpn/README".text = readFile ./README.openvpn;
    };

    networking.firewall =
    assert accessNets.ipv4 != cfg.roles.external_net.vxlan4;
    assert accessNets.ipv6 != cfg.roles.external_net.vxlan6;
    {
      allowedUDPPorts = [ 1194 ];
      extraCommands = ''
        ip46tables -t nat -N openvpn || true
        ip46tables -t nat -F openvpn
        iptables -t nat -A openvpn -s ${accessNets.ipv4} \! -d ${accessNets.ipv4} -j MASQUERADE
        ip6tables -t nat -A openvpn -s ${accessNets.ipv6} \! -d ${accessNets.ipv6} -j MASQUERADE

        ip46tables -t nat -D POSTROUTING -j openvpn || true
        ip46tables -t nat -A POSTROUTING -j openvpn
      '';
      extraStopCommands = ''
        ip46tables -t nat -D POSTROUTING -j openvpn || true
        ip46tables -t nat -F openvpn || true
        ip46tables -t nat -X openvpn || true
      '';
    };

    security.pam.services.openvpn.text = ''
      auth    required        pam_unix.so    shadow    nodelay
      account required        pam_unix.so
    '';

    services.openvpn.servers.access.config = serverConfig;

    system.activationScripts.openvpn-pki =
      lib.stringAfter [] ''
        ${pki}/generate-pki
        source ${pkgs.stdenv}/setup
        substitute ${ovpnTemplate} ${ovpn} \
          --subst-var-by caCrt "$(< ${pki.caCrt} )" \
          --subst-var-by clientCrt "$(< ${pki.clientCrt} )" \
          --subst-var-by clientKey "$(< ${pki.clientKey} )" \
          --subst-var-by ta "$(< ${pki.ta} )"
      '';

  };
}
