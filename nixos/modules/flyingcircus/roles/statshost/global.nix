{ config, lib, pkgs, ... }:
with lib;
{
  config = mkIf config.flyingcircus.roles.statshost.enable {

  relayName = location: "current-config/statshost-relay-${location}.json";

  jobs = map
    (p: { job_name = proxy.location;
          proxy_url = "${proxy.address}:9090";
          files = [ "/etc/${relayName proxy.location}" ];
          refresh_interval = "10m";
        })
    proxies;

  proxies =
    (filter
      (s: s.service == "stathostproxy-location")
      config.flyingcircus.enc_services);

  environment.etc = builtins.listToAttrs
    (map
     p: nameValuePair (relayName p.location) {
      text = builtins.toJSON
        (map
          (s: "${s.address}:9126")
          (filter
            (s: s.service == "stathost-collector" && s.location == p.location)
            config.flyingcircus.enc_services));
      }
    proxies);
}
