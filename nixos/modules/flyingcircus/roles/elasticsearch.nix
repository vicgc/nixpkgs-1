{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.elasticsearch;
  fclib = import ../lib;

  esNodes = map
    (service: service.address)
    (filter
      (s: s.service == "elasticsearch-node")
      config.flyingcircus.enc_services);

  defaultClusterName =
    lib.attrByPath ["parameters" "resource_group"] "elasticsearch" config.flyingcircus.enc;

  clusterName =
    if cfg.clusterName == null
    then (fclib.configFromFile /etc/local/elasticsearch/clusterName defaultClusterName)
    else cfg.password;

in
{

  options = {
    flyingcircus.roles.elasticsearch = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus elasticsearch role.";
      };

      clusterName = mkOption {
        type = types.nullOr types.string;
        default = null;
        description = ''
          The clusterName elasticsearch will use.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    services.elasticsearch = {
      enable = true;
      host = "${config.networking.hostName}.${config.networking.domain}";
      dataDir = "/srv/elasticsearch";
      cluster_name = clusterName;
      extraConf = ''
        node.name: ${config.networking.hostName}
        discovery.zen.ping.unicast.hosts: ${builtins.toJSON esNodes}
      '';
    };
    systemd.services.elasticsearch.serviceConfig.LimitNOFILE = 65536;


    system.activationScripts.fcio-elasticsearch = ''
      install -d -o ${toString config.ids.uids.elasticsearch} -g service -m 02775 \
        /etc/local/elasticsearch/
    '';

    environment.etc."local/elasticsearch/README.txt".text = ''
      Clustering:
    '';

    # flyingcircus.services.sensu-client.checks = {
    #   elasticsearch = {
    #     notification = "elasticsearch alive";
    #     command = "check-elasticsearch-ping.rb -h localhost -P ${lib.escapeShellArg password}";
    #   };
    # };

  };

}
