{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.datadog;

  localConfig =
    if pathExists /etc/local/datadog/datadog.json
    then builtins.fromJSON (readFile /etc/local/datadog/datadog.json)
    else {};

  config_files =
    listToAttrs
      (map
        (name: {
          name = name;
          value = readFile ("/etc/local/datadog/${name}");
        })
        (filter
          (name: hasSuffix ".yaml" name)
          (attrNames
            (builtins.readDir /etc/local/datadog))));

  ddHome = config.users.users.datadog.home;

in
{
  options = {
    flyingcircus.roles.datadog = {
      enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable the datadog role.";
      };
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.fcio-datadog = ''
      install -d -o root -g service -m 02775 /etc/local/datadog
      install -d -o datadog -g datadog -m 0755 ${ddHome}
    '';

    environment.etc."local/datadog/README.txt".text = ''
      Put your local datadog configuration as *JSON* into datadog.json. Example:

      {
        "api_key": "your-api-key",
        "hostname": "your-optional-alias",
        "tags": ["your", "tags", "(optional)"]
      }

      You may add YAML files (like mysql.yaml) files for further customization.
    '';

    services.dd-agent =
      localConfig // {
        enable = (localConfig != {});
        additionalConfig = config_files;
      };

    systemd.services.dogstatsd = {
      serviceConfig = lib.mkForce {
        ExecStart = "${pkgs.dd-agent}/bin/dogstatsd";
        User = "datadog";
        Group = "datadog";
        Type = "simple";
        PIDFile = "${ddHome}/dogstatsd.pid";
        Restart = "always";
        RestartSec = 2;
      };
      environment = { "TMPDIR" = ddHome; };
    };
  };
}
