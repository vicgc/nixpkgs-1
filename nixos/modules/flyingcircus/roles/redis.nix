{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.redis;
  fclib = import ../lib;

  listen_addresses =
    fclib.listenAddresses config "lo" ++
    fclib.listenAddresses config "ethsrv";

  generatedPassword =
    lib.removeSuffix "\n" (readFile
      (pkgs.runCommand "redis.password" {}
      "${pkgs.apg}/bin/apg -a 1 -M lnc -n 1 -m 32 > $out"));

  password =
    if cfg.password == null
    then (fclib.configFromFile /etc/local/redis/password generatedPassword)
    else cfg.password;

in
{

  options = {
    flyingcircus.roles.redis = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus Redis role.";
      };

      password = mkOption {
        type = types.nullOr types.string;
        default = null;
        description = ''
          The password for redis. If null, a random password will be generated.
        '';
      };

    };
  };

  config = mkIf cfg.enable {

    services.redis.enable = true;
    services.redis.requirePass = password;
    services.redis.bind = concatStringsSep " " listen_addresses;

    system.activationScripts.fcio-redis = ''
      install -d -o ${toString config.ids.uids.redis} -g service -m 02775 \
        /etc/local/redis/
      if [[ ! -e /etc/local/redis/password ]]; then
        (umask 027; echo ${lib.escapeShellArg password} > /etc/local/redis/password)
      fi
    '';

    flyingcircus.services.sensu-client.checks = {
      redis = {
        notification = "Redis alive";
        command = "check-redis-ping.rb -h localhost -P ${lib.escapeShellArg password}";
      };
    };

    boot.kernel.sysctl = {
      "vm.overcommit_memory" = 1;
      "net.core.somaxconn" = 512;
    };

  };

}
