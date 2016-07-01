{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.memcached;
  fclib = import ../lib;

  listen_addresses =
    fclib.listenAddresses config "ethsrv";

  defaultConfig = ''
  {
    "port": "11211",
    "maxMemory": "64",
    "maxConnections": "1024"
  }
  '';

  localConfig =
    if pathExists /etc/local/memcached/memcached.json
    then builtins.fromJSON (readFile /etc/local/memcached/memcached.json)
    else builtins.fromJSON defaultConfig;

in
{

  options = {

    flyingcircus.roles.memcached = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus memcached role.";
      };

    };
  };

  config = mkIf cfg.enable {

    system.activationScripts.fcio-memcached = ''
      install -d -o ${toString config.ids.uids.memcached} -g service  -m 02775 /etc/local/memcached/
    '';

    environment.etc."local/memcached/README.txt".text = ''
     Put your local memcached configuration as *JSON* into memcached.json.

     Example:
     ${defaultConfig}
    '';

    services.memcached =
      localConfig // {
       listen = head listen_addresses;
       enable = true;
      };

    flyingcircus.services.sensu-client.checks = {
      memcached = {
        notification = "memcached alive";
        command = "check-memcached-stats.rb -h ${head listen_addresses}";
	};
    };

  };

}

