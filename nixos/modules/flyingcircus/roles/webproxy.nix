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

  config = mkMerge [
  (mkIf cfg.enable {

    services.varnish.enable = true;
    services.varnish.http_address =
      lib.concatMapStringsSep ","
        (addr: "${addr}:8008")
        ((fclib.listenAddressesQuotedV6 config "ethsrv") ++
         (fclib.listenAddressesQuotedV6 config "lo"));
    services.varnish.config = varnishCfg;
    services.varnish.stateDir = "/var/spool/varnish/${config.networking.hostName}";
    # XXX: needs to be migrated to varnish service
    systemd.services.varnish.after = [ "network.target" ];

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

    services.telegraf.inputs = {
      varnish = [{
        binary = "${pkgs.varnish}/bin/varnishstat";
        stats = ["all"];
      }];
    };

  })

  {
    flyingcircus.roles.statshost.prometheusMetricRelabel = [
      { source_labels = ["__name__"];
       regex = "(varnish_client_req|varnish_fetch)_(.+)";
       replacement = "\${2}";
       target_label = "status";
      }
      { source_labels = ["__name__"];
       regex = "(varnish_client_req|varnish_fetch)_(.+)";
       replacement = "\${1}";
       target_label = "__name__";
      }

      # Relabel
      { source_labels = ["__name__"];
       regex = "varnish_(\\w+)_(.+)__(\\d+)__(.+)";
       replacement = "\${1}";
       target_label = "backend";
      }
      { source_labels = ["__name__"];
       regex = "varnish_(\1\w+)_(.+)__(\\d+)__(.+)";
       replacement = "varnish_\${4}";
       target_label = "__name__";
      }
    ];
  }

  ];

}
