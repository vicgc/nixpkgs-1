{ config, pkgs, lib, ... }:
let
  enc = config.flyingcircus.enc;

in
{

  services.collectd.enable = true;
  services.collectd.extraConfig = ''
    Interval     5

    LoadPlugin cpu
    LoadPlugin disk
    LoadPlugin entropy
    LoadPlugin interface
    LoadPlugin load
    LoadPlugin processes
    LoadPlugin swap
    LoadPlugin syslog
    LoadPlugin uptime
    LoadPlugin vmem
    LoadPlugin write_graphite

    <Plugin "syslog">
        LogLevel info
    </Plugin>

    <Plugin "cpu">
      ReportByCpu true
      ReportByState true
      ValuesPercentage true
    </Plugin>

    <Plugin "disk">
      Disk "/^[sv]d[a-z]$|^vg.*-./"
      UdevNameAttr "DM_NAME"
    </Plugin>

    <Plugin "write_graphite">
     <Node "services16">
       Host "stats.flyingcircus.io"
       Port "2003"
       Prefix "fcio.${enc.parameters.location}.${enc.parameters.resource_group}.virtual.generic."
       Protocol "udp"
       EscapeCharacter "_"
       SeparateInstances true
     </Node>
    </Plugin>

    ${builtins.concatStringsSep "\n" (map
        (ifname: ''
          <Plugin "interface">
            Interface "${ifname}"
          </Plugin>
         '')
        (builtins.attrNames config.networking.interfaces))}

    }
  '';

}
