{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.varnish;

  nonEmptyString = string: if stringLength string > 0 then true else false;
  configFromFile = file: default:
    findFirst (nonEmptyString) default [
      (if (builtins.pathExists file)
       then builtins.readFile file
       else "")
      ];
  varnishCfg = configFromFile /etc/local/varnish/default.vcl example;
  example = ''
    vcl 4.0;
    backend test {
      .host = "127.0.0.1";
      .port = "8080";
    }
  '';

in

{

  options = {

    flyingcircus.roles.varnish = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus varnish server role.";
      };

    };

  };

  config = mkIf cfg.enable {

    services.varnish.enable = true;
    services.varnish.http_address = "localhost:8008";
    services.varnish.config = varnishCfg;

    system.activationScripts.varnish = ''
      install -d -o ${toString config.ids.uids.varnish} -g service -m 02775 /etc/local/varnish
    '';


    environment.etc = {
      "local/varnish/README.txt".text = ''
        Varnish is enabled on this machine.

        Varnish is listening on: ${config.services.varnish.http_address}

        Put your configuration into `default.vcl`.
      '';
      "local/varnish/default.vcl.example".text = example;
    };
  };
}
