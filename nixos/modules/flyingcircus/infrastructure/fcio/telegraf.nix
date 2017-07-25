{ config, pkgs, lib, ... }:
with lib;

let
  fclib = import ../../lib;
  enc = config.flyingcircus.enc;
  params = if enc ? parameters then enc.parameters else {};
in
mkIf (params ? location && params ? resource_group) {

  services.telegraf.enable = true;
  services.telegraf.extraConfig = {
    global_tags = {
        location = params.location;
        resource_group = params.resource_group;
    };
    outputs = {
      prometheus_client = {
        listen = "${lib.head(
          fclib.listenAddressesQuotedV6 config "ethsrv")}:9126";
      };
    };
    inputs = {
      cpu = {
        percpu = false;
        totalcpu = true;
      };
      disk = {
        mount_points = [
          "/"
          "/tmp"
        ];
      };
      diskio = {
        skip_serial_number = true;
      };
      kernel = {};
      mem = {};
      netstat = {};
      net = {};
      processes = {};
      system = {};
      swap = {};
    };
  };
}
