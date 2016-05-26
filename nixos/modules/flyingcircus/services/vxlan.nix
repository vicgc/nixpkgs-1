{ vid
, gw4
, gw6
, local
, remote
, tunneldev
, realdev ? "ethfe"
, pkgs ? import <nixpkgs> { }
, lib ? pkgs.lib
}:

let
  ip = "${pkgs.iproute}/bin/ip";

in

{
  systemd.services."network-external-${tunneldev}" = {
    description = "VxLAN tunnel ${tunneldev}";
    after = [ "network.target" ];
    wantedBy = [ "multiuser.target" ];
    bindsTo = [ "sys-subsystem-net-devices-${realdev}.device" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeScript "network-external-${tunneldev}-start" ''
        #! ${pkgs.stdenv.shell} -e
        echo "adding link ${tunneldev}"
        ${ip} link del ${tunneldev} 2>/dev/null || true
        ${ip} link add ${tunneldev} type vxlan id ${builtins.toString vid} \
          dev ${realdev} local ${local} remote ${remote} dstport 8472
        ${ip} link set ${tunneldev} up
        ${ip} -4 addr add ${gw4} dev ${tunneldev}
        ${ip} -6 addr add ${gw6} dev ${tunneldev}
      '';
      ExecStop = pkgs.writeScript "network-external-${tunneldev}-stop" ''
        #! ${pkgs.stdenv.shell} -e
        echo "removing link ${tunneldev}"
        ${ip} link set ${tunneldev} down
        ${ip} link del ${tunneldev}
      '';
      RemainAfterExit = true;
    };
  };
}
