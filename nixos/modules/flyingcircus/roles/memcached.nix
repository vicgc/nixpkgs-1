{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.memcached;
  fclib = import ../lib;

  srv = fclib.listenAddresses config "ethsrv";

  defaultConfig = ''
    {
      "port": 11211,
      "maxMemory": 64,
      "maxConnections": 1024
    }
  '';

  localConfig =
    fclib.jsonFromFile "/etc/local/memcached/memcached.json" defaultConfig;

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
      install -d -o ${toString config.ids.uids.memcached} -g service -m 02775 \
        /etc/local/memcached
    '';

    environment.etc = {
      "local/memcached/README.txt".text = ''
        Put your local memcached configuration as JSON into `memcached.json`.

        Example:
        ${defaultConfig}
      '';
      "local/memcached/memcached.json.example".text = defaultConfig;
    };

    services.memcached = {
      enable = true;
      listen = concatStringsSep "," srv;
    } // localConfig;

    flyingcircus.services.sensu-client.checks.memcached =
      let
        addr = head srv;
        port = localConfig.port;
      in {
        notification = "memcached alive";
        command = "check-memcached-stats.rb -h ${addr} -p ${toString port}";
      };

  };
}
