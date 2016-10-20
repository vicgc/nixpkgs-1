{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.elasticsearch;
  fclib = import ../lib;

  esNodes = map
    (service: service.address)
    (filter
      (s: s.service == "elasticsearch-node")
      config.flyingcircus.enc_services);
  thisNode = "${config.networking.hostName}.${config.networking.domain}";

  defaultClusterName = config.networking.hostName;

  clusterName =
    if cfg.clusterName == null
    then (fclib.configFromFile /etc/local/elasticsearch/clusterName defaultClusterName)
    else cfg.password;

  currentMemory = fclib.current_memory config 1024;
  esHeap =
    fclib.min [
      (currentMemory / 2)
      (31 * 1024)];

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
      host = thisNode;
      dataDir = "/srv/elasticsearch";
      cluster_name = clusterName;
      extraConf = ''
        node.name: ${config.networking.hostName}
        discovery.zen.ping.unicast.hosts: ${builtins.toJSON esNodes}
        bootstrap.memory_lock: true
      '';
    };
    systemd.services.elasticsearch = {
      environment = {
        ES_HEAP_SIZE = "${toString esHeap}m";
      };
      serviceConfig.LimitNOFILE = 65536;
      serviceConfig.LimitMEMLOCK = "infinity";
    };

    # System tweaks
    boot.kernel.sysctl = {
      "vm.max_map_count" = "262144";
    };

    system.activationScripts.fcio-elasticsearch = ''
      install -d -o ${toString config.ids.uids.elasticsearch} -g service -m 02775 \
        /etc/local/elasticsearch/
    '';

    environment.etc."local/elasticsearch/README.txt".text = ''
      Clustering:
    '';

    flyingcircus.services.sensu-client.checks = {

      es_circuit_breakers = {
        notification = "ES: Circuit Breakers active";
        command = "check-es-circuit-breakers.rb -h ${thisNode}";
      };

      es_cluster_health = {
        notification = "ES: Cluster Health";
        command = "check-es-cluster-health.rb -h ${thisNode}";
      };

      es_file_descriptor = {
        notification = "ES: File descriptors in use";
        command = "check-es-file-descriptors.rb -h ${thisNode}";
      };

      es_heap = {
        notification = "ES: Heap too full";
        command = "check-es-heap.rb -h ${thisNode} -w 75 -c 90 -P";
      };

      es_node_status = {
        notification = "ES: Node status";
        command = "check-es-node-status.rb -h ${thisNode}";
      };

      es_shard_allocation_status = {
        notification = "ES: Shard allocation status";
        command = "check-es-shard-allocation-status.rb -s ${thisNode}";
      };

    };

  };

}
