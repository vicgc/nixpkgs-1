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

  cacheMemory =
    (fclib.current_memory config 256)
    / 100 * cfg.mallocMemoryPercentage;

  varnish_ = "${pkgs.varnish}/sbin/varnishd -a ${config.services.varnish.http_address} -f ${pkgs.writeText "default.vcl" config.services.varnish.config} -n ${config.services.varnish.stateDir} -u varnish -s malloc,${toString cacheMemory}M";

in

{

  options = {

    flyingcircus.roles.webproxy = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus varnish server role.";
      };

      mallocMemoryPercentage = mkOption {
        type = types.int;
        default = 50;
        description = "Percentage of system memory to allocate to malloc cache";
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
    systemd.services.varnish = {
      # XXX: needs to be migrated to varnish service
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = (lib.mkOverride 99 varnish_);
      };
    };

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
