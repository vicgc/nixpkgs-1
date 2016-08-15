{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.webproxy;
  fclib = import ../lib;

  varnishCfg = fclib.configFromFile /etc/local/varnish/default.vcl vcl_example;

  vcl_example = ''
    vcl 4.0;
    backend test {
      .host = "127.0.0.1";
      .port = "8080";
    }
  '';

in

{

  options = {

    flyingcircus.roles.webproxy = {
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
    services.varnish.stateDir = "/var/spool/varnish/${config.networking.hostName}";

    system.activationScripts.varnish = ''
      install -d -o ${toString config.ids.uids.varnish} -g service -m 02775 /etc/local/varnish
    '';

    environment.etc = {
      "local/varnish/README.txt".text = ''
        Varnish is enabled on this machine.

        Varnish is listening on: ${config.services.varnish.http_address}

        Put your configuration into `default.vcl`.
      '';
      "local/varnish/default.vcl.example".text = vcl_example;
    };

  };
}
