{ lib }:
with lib;
rec {

  # get the DN of this node for LDAP logins.
  getLdapNodeDN = config:
    "cn=${config.networking.hostName},ou=Nodes,dc=gocept,dc=com";

  # Compute LDAP password for this node.
  getLdapNodePassword = config:
    builtins.hashString "sha256" (concatStringsSep "/" [
      "ldap"
      config.flyingcircus.enc.parameters.directory_password
      config.networking.hostName
    ]);

  listServiceAddresses = config: service:
    (map
      (service: service.address)
      (filter
        (s: s.service == service)
        config.flyingcircus.enc_services));

  listServiceAddressesWithPort = config: service: port:
    map
      (address: "${address}:${toString port}")
      (listServiceAddresses config service);

  mkPlatform = lib.mkOverride 900;

}
