{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.elasticsearch;
  cfg_service = config.services.elasticsearch;
  fclib = import ../lib;

  package =
    if config.flyingcircus.roles.elasticsearch5.enable
    then pkgs.elasticsearch5
    else if config.flyingcircus.roles.elasticsearch2.enable
    then pkgs.elasticsearch2
    # XXX remove after finishing migration
    else if config.flyingcircus.roles.elasticsearch.enable
    then pkgs.elasticsearch2
    else null;

  enabled = package != null;

  esNodes =
    if cfg.esNodes == null
    then map
      (service: service.address)
      (filter
        (s: s.service == "elasticsearch-node")
        config.flyingcircus.enc_services)
    else cfg.esNodes;

  thisNode =
    if config.networking.domain != null
    then "${config.networking.hostName}.${config.networking.domain}"
    else "localhost";

  defaultClusterName = config.networking.hostName;

  clusterName =
    if cfg.clusterName == null
    then (fclib.configFromFile /etc/local/elasticsearch/clusterName defaultClusterName)
    else cfg.clusterName;

  additionalConfig =
    fclib.configFromFile /etc/local/elasticsearch/elasticsearch.yml "";

  currentMemory = fclib.current_memory config 1024;

  esHeap =
    fclib.min [
      (currentMemory * cfg.heapPercentage / 100)
      (31 * 1024)];

in
{

  options = {

    flyingcircus.roles.elasticsearch = {

      # This option is there for migration. After the release is out, each
      # node with the elasticsearch role needs to get the elasticsearch2 role
      # instead. The option can be removed then.
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus elasticsearch2 role.";
      };

      clusterName = mkOption {
        type = types.nullOr types.string;
        default = null;
        description = ''
          The clusterName elasticsearch will use.
        '';
      };

      dataDir = mkOption {
        type = types.path;
        default = "/srv/elasticsearch";
        description = ''
          Data directory for elasticsearch.
        '';
      };

      heapPercentage = mkOption {
        type = types.int;
        default = 50;
        description = ''
          Tweak amount of memory to use for ES heap
          (systemMemory * heapPercentage / 100)
        '';
      };

      esNodes = mkOption {
        type = types.nullOr (types.listOf types.string);
        default = null;
      };
    };


    flyingcircus.roles.elasticsearch2 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus elasticsearch2 role.";
      };
    };


    flyingcircus.roles.elasticsearch5 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus elasticsearch5 role.";
      };
    };

  };

  config = mkIf enabled {

    services.elasticsearch = {
      enable = true;
      package = package;
      listenAddress = thisNode;
      dataDir = cfg.dataDir;
      cluster_name = clusterName;
      extraJavaOptions = [
       "-Des.path.scripts=${cfg_service.dataDir}/scripts"
       "-Des.security.manager.enabled=false"
        "-Xms${toString esHeap}m"
        "-Xmx${toString esHeap}m"
      ];
      extraConf = ''
        node.name: ${config.networking.hostName}
        discovery.zen.ping.unicast.hosts: ${builtins.toJSON esNodes}
        bootstrap.memory_lock: true
        ${additionalConfig}
      '';
    };

    systemd.services.elasticsearch = {
      serviceConfig = {
        LimitMEMLOCK = "infinity";
      };
      preStart = mkAfter ''
        # Install scripts
        mkdir -p ${cfg_service.dataDir}/scripts
      '';
      postStart = let
        url = "http://${thisNode}:9200/_cat/health";
        in ''
        # Wait until available for use
        for count in {0..120}; do
            ${pkgs.curl}/bin/curl -s ${url} && exit
            echo "Trying to connect to ${url} for ''${count}s"
            sleep 1
        done
        echo "No connection to ${url} for 120s, giving up"
        exit 1
      '';
    };

    system.activationScripts.fcio-elasticsearch = ''
      install -d -o ${toString config.ids.uids.elasticsearch} -g service -m 02775 \
        /etc/local/elasticsearch/
    '';

    environment.etc."local/elasticsearch/README.txt".text = ''
      Elasticsearch is running on this VM.

      It is forming the cluster named ${clusterName}
      To change the cluster name, add a file named "clusterName" here, with the
      cluster name as its sole contents.

      To add additional configuration options, create a file "elasticsearch.yml"
      here. Its contents will be appended to the base configuration.
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
        command = "check-es-heap.rb -h ${thisNode} -w 80 -c 90 -P";
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

    services.collectd.extraConfig = ''
      LoadPlugin curl_json
      <Plugin curl_json>
        <URL "http://${thisNode}:9200/_cluster/health">
          Header "Accept: application/json"
          Instance "elasticsearch"
          <Key "number_of_data_nodes">
            Type "gauge"
          </Key>
          <Key "active_shards">
            Type "gauge"
          </Key>
          <Key "active_primary_shards">
            Type "gauge"
          </Key>
          <Key "unassigned_shards">
            Type "gauge"
          </Key>
          <Key "initializing_shards">
            Type "gauge"
          </Key>
          <Key "number_of_pending_tasks">
            Type "gauge"
          </Key>
          <Key "relocating_shards">
            Type "gauge"
          </Key>
        </URL>

        <URL "http://${thisNode}:9200/_nodes/${config.networking.hostName}/stats">
          Header "Accept: application/json"
          Instance "elasticsearch"
          <Key "nodes/*/jvm/mem/heap_used_in_bytes">
            Type "gauge"
          </Key>
          <Key "nodes/*/jvm/mem/heap_committed_in_bytes">
            Type "gauge"
          </Key>
          <Key "nodes/*/jvm/threads/count">
            Type "gauge"
            Instance "thread_count"
          </Key>
          <Key "nodes/*/http/total_opened">
            Type "derive"
            Instance "http_requests"
          </Key>
          <Key "nodes/*/indices/docs/count">
            Type "gauge"
            Instance "indexed_docs"
          </Key>

          <Key "nodes/*/indices/search/query_total">
            Type "derive"
          </Key>
          <Key "nodes/*/indices/search/query_time_in_millis">
            Type "derive"
          </Key>
          <Key "nodes/*/indices/search/fetch_total">
            Type "derive"
          </Key>
          <Key "nodes/*/indices/search/fetch_time_in_millis">
            Type "derive"
          </Key>
          <Key "nodes/*/indices/indexing/index_total">
            Type "derive"
          </Key>
          <Key "nodes/*/indices/indexing/index_time_in_millis">
            Type "derive"
          </Key>
          <Key "nodes/*/indices/refresh/total">
            Type "derive"
          </Key>
          <Key "nodes/*/indices/refresh/total_time_in_millis">
            Type "derive"
          </Key>
          <Key "nodes/*/indices/flush/total">
            Type "derive"
          </Key>
          <Key "nodes/*/indices/flush/total_time_in_millis">
            Type "derive"
          </Key>
        </URL>
      </Plugin>'';

  };
}
