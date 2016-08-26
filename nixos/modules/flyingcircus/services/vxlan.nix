# Configures a single VxLAN tunnel as systemd job.

{ vid  # VxLAN virtual network id
, gw4  # (inner) IPv4 address of the tunnel device
, gw6  # (inner) IPv6 address of the tunnel device
, local  # outer tunnel endpoint address
, remote  # outer tunnel endpoint address
, realdev ? "ethfe"  # outer network device
, port ? 8472
, dev  ? "nx0"  # tunnel device on the gateway
, mtu ? 1420  # tunnel MTU
, pkgs ? import <nixpkgs> { }
, lib ? pkgs.lib
}:

{
  systemd.services."vxlan-${dev}" = rec {
    description = "VxLAN tunnel ${dev}";
    after = [ "network-addresses-${realdev}.service" ];
    wantedBy = [ "dnsmasq.service" ];
    before = wantedBy;
    bindsTo = [ "sys-subsystem-net-devices-${realdev}.device" ];

    serviceConfig =
      let ip = "${pkgs.iproute}/bin/ip";
      in
      {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeScript "vxlan-${dev}-start" ''
          #!${pkgs.stdenv.shell} -e
          echo "adding link ${dev}"
          ${ip} link del ${dev} 2>/dev/null || true
          ${ip} link add ${dev} type vxlan id ${toString vid} \
            dev ${realdev} local ${local} remote ${remote} \
            dstport ${toString port}
          ${ip} link set up mtu ${toString mtu} dev ${dev}
          ${ip} -4 addr add ${gw4} dev ${dev}
          ${ip} -6 addr add ${gw6} dev ${dev}
        '';
        ExecStop = pkgs.writeScript "vxlan-${dev}-stop" ''
          #!${pkgs.stdenv.shell} -e
          echo "removing link ${dev}"
          ${ip} link set ${dev} down
          ${ip} link del ${dev}
        '';
      };
  };
}
