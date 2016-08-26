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
    # does not interact well with old-style policy routing
    flyingcircus.network.policyRouting.enable = lib.mkForce false;

    flyingcircus.roles.openvpn.enable = true;

    environment.systemPackages = [ pkgs.mosh ];

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv6.conf.default.forwarding" = 1;
    };
  };
}
