# Managed external network (OpenVPN/DHP/...) gateway
{ lib, config, pkgs, ... }:

let
  cfg = config.flyingcircus;

in
{
  imports = [ ./openvpn.nix ];

  options = {
    flyingcircus.roles.external_net.enable = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.roles.external_net.enable {
    flyingcircus.roles.openvpn.enable = true;
    environment.systemPackages = [ pkgs.mosh ];
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv6.conf.default.forwarding" = 1;
    };
  };
}
