{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.flyingcircus;
  mail_out_service = lib.findFirst
    (s: s.service == "mailserver-mailout")
    null
    config.flyingcircus.enc_services;

in
{
  config = mkIf (!cfg.roles.mailserver.enable && mail_out_service != null) {

    networking.defaultMailServer.directDelivery = true;
    networking.defaultMailServer.hostName = mail_out_service.address;

    networking.defaultMailServer.root = "admin@flyingcircus.io";
    networking.defaultMailServer.domain = "fcio.net";
  };
}
