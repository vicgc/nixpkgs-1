{ config, pkgs, lib, ... }:
with lib;

let
  fclib = import ../../lib;
  enc = config.flyingcircus.enc;
  params = if enc ? parameters then enc.parameters else {};

  port = "9126";

in
mkIf (params ? location && params ? resource_group) {

  services.telegraf.enable = true;
  services.telegraf.configDir =
    if builtins.pathExists "/etc/local/telegraf"
    then /etc/local/telegraf
    else null;
  services.telegraf.extraConfig = {
    global_tags = {
        location = params.location;
        resource_group = params.resource_group;
    };
    outputs = {
      prometheus_client = {
        listen = "${lib.head(
          fclib.listenAddressesQuotedV6 config "ethsrv")}:${port}";
      };
    };
  };
  services.telegraf.inputs = {
    cpu = [{
      percpu = false;
      totalcpu = true;
    }];
    disk = [{
      mount_points = [
        "/"
        "/tmp"
      ];
    }];
    diskio = [{
      skip_serial_number = true;
    }];
    kernel = [{}];
    mem = [{}];
    netstat = [{}];
    net = [{}];
    processes = [{}];
    system = [{}];
    swap = [{}];
  };

  systemd.services.telegraf.serviceConfig = {
    PermissionsStartOnly = "true";
    ExecStartPre = ''
      ${pkgs.coreutils}/bin/install -d -o root -g service -m 02775 \
        /etc/local/telegraf
    '';
  };

  environment.etc."local/telegraf/README.txt".text = ''
    There is a telegraf daemon running on this machine to gather statistics.
    To gather additional or custom statistis add a proper configuration file
    here. `*.conf` will beloaded.

    See https://github.com/influxdata/telegraf/blob/master/docs/CONFIGURATION.md
    for details on how to configure telegraf.
  '';

  flyingcircus.services.sensu-client.checks = {
    telegraph_prometheus_output = {
      notification = "Telegraf prometheus output alive";
      command = ''
        check_http -H ${config.networking.hostName} -p ${port} \
          -u /metrics
      '';
    };
  };

}
