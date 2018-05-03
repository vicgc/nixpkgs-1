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

  configFile = pkgs.writeText "default.vcl" config.services.varnish.config;
  varnish_ = "${pkgs.varnish}/sbin/varnishd -a ${config.services.varnish.http_address} -f /etc/current-config/varnish.vcl -n ${config.services.varnish.stateDir} -u varnish -s malloc,${toString cacheMemory}M";

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
      # XXX: needs to be migrated to upstream varnish service
      after = [ "network.target" ];
      path = [ pkgs.varnish pkgs.procps pkgs.gawk ];
      preStart = lib.mkAfter ''
        install -d -o ${toString config.ids.uids.varnish} -g service -m 02775 /etc/local/varnish
      '';
      reloadIfChanged = true;
      restartTriggers = [ configFile ];
      reload = ''
        if pgrep -a varnish | grep  -Fq '${varnish_}'
        then
          config=$(readlink -e /etc/current-config/varnish.vcl)
          varnishadm vcl.load $config $config &&
            varnishadm vcl.use $config

          for vcl in $(varnishadm vcl.list | grep ^available | awk {'print $3'});
          do
            varnishadm vcl.discard $vcl
          done
        else
          echo "Binary or parameters changed. Restarting."
          systemctl restart varnish
        fi
      '';

      serviceConfig = {
        ExecStart = (lib.mkOverride 99 varnish_);
      };
    };

    environment.etc = {
      "local/varnish/README.txt".text = ''
        Varnish is enabled on this machine.

        Varnish is listening on: ${config.services.varnish.http_address}

        Put your configuration into `default.vcl`.
      '';
      "local/varnish/default.vcl.example".text = vcl_example;
      "current-config/varnish.vcl".source = configFile;
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
      {
        source_labels = [ "__name__" ];
        regex = "(varnish_client_req|varnish_fetch)_(.+)";
        replacement = "\${2}";
        target_label = "status";
      }
      {
        source_labels = [ "__name__" ];
        regex = "(varnish_client_req|varnish_fetch)_(.+)";
        replacement = "\${1}";
        target_label = "__name__";
      }

      # Relabel
      {
        source_labels = [ "__name__" ];
        regex = "varnish_(\\w+)_(.+)__(\\d+)__(.+)";
        replacement = "\${1}";
        target_label = "backend";
      }
      {
        source_labels = [ "__name__" ];
        regex = "varnish_(\1\w+)_(.+)__(\\d+)__(.+)";
        replacement = "varnish_\${4}";
        target_label = "__name__";
      }
    ];
    flyingcircus.roles.statshost.globalAllowedMetrics = [ "varnish" ];
  }
  ];
}
