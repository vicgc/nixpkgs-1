{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.flyingcircus.roles.loghost;
  fclib = import ../lib;

  loghostService = findFirst
    (s: s.service == "loghost-server")
    null
    config.flyingcircus.enc_services;

  # It's common to have stathost and loghost on the same node. Each should
  # use half of the memory then. A general approach for this kind of
  # multi-service would be nice.
  heapCorrection =
    if config.flyingcircus.roles.statshost-master.enable
    then 50
    else 100;

in
{

  options = {

    flyingcircus.roles.loghost = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''Enable the Flying Circus loghost role.

        This role enables the full graylog stack at once (GL, ES, Mongo).

        '';
      };

    };

  };

  config = mkIf cfg.enable {

    flyingcircus.roles.graylog = {
      enable = true;
      heapPercentage = 15 * heapCorrection / 100;
      cluster = false;
      esNodes = [
        "http://${config.networking.hostName}.${config.networking.domain}:9200"
      ];
    };

    flyingcircus.roles.elasticsearch2.enable = true;
    flyingcircus.roles.elasticsearch = {
      dataDir = "/var/lib/elasticsearch";
      clusterName = "graylog";
      heapPercentage = 35 * heapCorrection / 100;
    };

  };

}
