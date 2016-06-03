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
      install -d -o root -g service  -m 02775 /etc/local/datadog/
    '';

    environment.etc."local/datadog/README.txt".text = ''
      Put your local datadog configuration as *JSON* into datadog.json. Example:

      {
        "api_key": "your-api-key",
        "hostname": "your-optional-alias",
        "tags": ["your", "tags", "(optional)"]
      }

      Additionally you may add .yaml (like mysql.yaml) files for further customization.

    '';

    services.dd-agent =
      localConfig // {
        enable = (localConfig != {});
        additionalConfig = config_files;
      };
  };
}
