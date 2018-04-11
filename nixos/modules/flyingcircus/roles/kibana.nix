# Stub role which is only useful with VPN or other means of access.
{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.flyingcircus.roles.kibana;
  fclib = import ../lib;

  elasticSearchUrl =
    if cfg.elasticSearchUrl == null
    then (
          removeSuffix "\n"
            (fclib.configFromFile /etc/local/kibana/elasticSearchUrl null))
    else cfg.elasticSearchUrl;


in
{
  options = {

    flyingcircus.roles.kibana = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus Kibana server role.";
      };

      elasticSearchUrl = lib.mkOption {
        type = types.nullOr types.str;
        default = null;  # XXX: auto-use a local ES?
        description = "URL to elasticsearch";
      };

    };

  };

  config = mkMerge [
    (mkIf (cfg.enable && elasticSearchUrl != null) {
      services.kibana = {
        enable = true;
        listenAddress = lib.head (
          fclib.listenAddresses config "ethsrv"
          ++
          fclib.listenAddresses config "lo"
          );
        elasticsearch.url = elasticSearchUrl;
      };
    })

    (mkIf cfg.enable {
      environment.etc."local/kibana/README.txt".text = ''
        Kibana local configuration

        To configure the ElasticSearch kibana connects to, add a file `elasticSearchUrl`
        here, and put the URL in.

        Run `sudo fc-manage --build` to activate the configuraiton.
      '';

      system.activationScripts.dovecot = ''
        install -d -g service -m 0775 /etc/local/kibana
      '';
    })

  ];
}
