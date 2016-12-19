{ config, lib, pkgs, ... }:
with lib;

# NOTE: This is mostly duplicate of
# nixos/modules/services/search/elasticsearch.nix. Once we get upstream updated
# this can probably go away.

let
  cfg = config.services.elasticsearch;

  esConfig = ''
    network.host: ${cfg.host}
    network.port: ${toString cfg.port}
    network.tcp.port: ${toString cfg.tcp_port}
    cluster.name: ${cfg.cluster_name}
    ${cfg.extraConf}
  '';

  configDir = pkgs.buildEnv {
    name = "elasticsearch-config";
    paths = [
      (pkgs.writeTextDir "elasticsearch.yml" esConfig)
      (pkgs.writeTextDir "logging.yml" cfg.logging)
    ];
  };

  esPlugins = pkgs.buildEnv {
    name = "elasticsearch-plugins";
    paths = cfg.plugins;
  };


in {

  config = {

   systemd.services.elasticsearch = {
      serviceConfig.ExecStart = mkForce "${pkgs.elasticsearch}/bin/elasticsearch -Des.path.conf=${cfg.dataDir}/config -Des.path.scripts=${cfg.dataDir}/scripts ${toString cfg.extraCmdLineOptions}";
      preStart = mkForce ''
        mkdir -m 0700 -p ${cfg.dataDir}
        if [ "$(id -u)" = 0 ]; then chown -R elasticsearch ${cfg.dataDir}; fi

        # Install plugins
        rm ${cfg.dataDir}/plugins || true
        ln -s ${esPlugins} ${cfg.dataDir}/plugins

        # Install scripts
        mkdir -p ${cfg.dataDir}/scripts

        # Install config
        rm -rf ${cfg.dataDir}/config || true
        mkdir -p ${cfg.dataDir}/config
        cp -L ${configDir}/* ${cfg.dataDir}/config/
      '';

    };

  };

}
