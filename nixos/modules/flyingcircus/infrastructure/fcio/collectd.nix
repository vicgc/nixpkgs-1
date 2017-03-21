{ config, pkgs, lib, ... }:
with lib;

let
  enc = config.flyingcircus.enc;
  params = if enc ? parameters then enc.parameters else {};

  # If there is no proxy service available, we directly talk to the statshost.
  proxy_service = lib.findFirst
    (s: s.service == "statshostproxy-collector")
    null
    config.flyingcircus.enc_services;

  # NOTE: We don't use the "service" for statsohst, because it returns the
  # SRV address. We need FE as we push data in from all over the place.
  # XXX: Testing-Mode: Fix to stats, but also send to proxy_service (see config
  # below)
  graphite_server = "stats.flyingcircus.io";
    # if proxy_service != null
    # then proxy_service.address
    # else "stats.flyingcircus.io";

in
mkIf (params ? location && params ? resource_group) {
  services.collectd.enable = true;
  services.collectd.extraConfig = ''
    Interval 5

    LoadPlugin cpu
    LoadPlugin disk
    LoadPlugin entropy
    LoadPlugin interface
    LoadPlugin load
    LoadPlugin memory
    LoadPlugin processes
    LoadPlugin swap
    LoadPlugin syslog
    LoadPlugin vmem
    LoadPlugin write_graphite

    <LoadPlugin uptime>
      Interval 360
    </LoadPlugin>

    <Plugin "syslog">
        LogLevel info
    </Plugin>

    <LoadPlugin df>
      Interval 360
    </LoadPlugin>
    <Plugin df>
      MountPoint "/"
      MountPoint "/tmp"
    </Plugin>

    <Plugin "disk">
      Disk "/^[sv]d[a-z]$|^vg.*-./"
    </Plugin>

    <Plugin "write_graphite">
      <Node "${graphite_server}">
        Host "${graphite_server}";
        Port "2003"
        Prefix "fcio.${params.location}.${params.resource_group}.virtual.generic."
        Protocol "udp"
        EscapeCharacter "_"
        SeparateInstances true
      </Node>
      ${optionalString (proxy_service != null) ''
        <Node "${proxy_service.address}">
          Host "${proxy_service.address}";
          Port "2003"
          Prefix "fcio.${params.location}.${params.resource_group}.virtual.generic."
          Protocol "udp"
          EscapeCharacter "_"
          SeparateInstances true
        </Node>
      ''}
    </Plugin>
  '' +
  concatMapStringsSep "\n"
    (ifname: ''
      <Plugin "interface">
        Interface "${ifname}"
      </Plugin>
     '')
     (attrNames config.networking.interfaces);
}
