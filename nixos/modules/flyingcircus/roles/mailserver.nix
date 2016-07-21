{ config, lib, pkgs, ... }:

let

  cfg = config.flyingcircus;
  fclib = import ../lib;

  mail_out_service = lib.findFirst
    (s: s.service == "mailserver-mailout")
    null
    config.flyingcircus.enc_services;


  config_options = [
    (if lib.pathExists "/etc/local/postfix/local.cf" then
      lib.readFile /etc/local/postfix/local.cf
     else "")

    (if lib.pathExists "/etc/local/postfix/canonical.pcre" then
      "canonical_maps = pcre:${/etc/local/postfix/canonical.pcre}\n"
     else "")

  ];

in
{
  options = {

    flyingcircus.roles.mailserver = {

      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enable the Flying Circus mailserver out role and configure
          mailout on all nodes in this RG/location.
        '';
      };

    };
  };

  config = lib.mkMerge [

   (lib.mkIf cfg.roles.mailserver.enable {
      services.postfix.enable = true;

      # Allow all networks on the SRV interface. We expect only trusted machines
      # can reach us there (firewall).
      services.postfix.networks =
        if cfg.enc.parameters.interfaces ? srv
        then builtins.attrNames cfg.enc.parameters.interfaces.srv.networks
        else [];

      system.activationScripts.fcio-postfix = ''
          install -d -o root -g service  -m 02775 /etc/local/postfix/
        '';

      environment.etc."local/postfix/README.txt".text = ''
        Put your local postfix configuration here.

        Use local.cf for pure configuration settings like
        setting message_size_limit. Please do use normal main.cf syntax,
        as this will extend the basic configuration file.

        If you need to reference to some map, these are currently available:
        * canonical.pcre

        In case you need to extend this list, get in contact with our
        support.
      '';

      services.postfix.extraConfig = lib.concatStringsSep "\n" config_options;

    })

    (lib.mkIf (!cfg.roles.mailserver.enable &&
           mail_out_service != null) {

      networking.defaultMailServer.directDelivery = true;
      networking.defaultMailServer.hostName = mail_out_service.address;

      networking.defaultMailServer.root = "admin@flyingcircus.io";
      networking.defaultMailServer.domain = "fcio.net";

      # Other parts of nixos (cron, mail) expect a suidwrapper for sendmail.
      services.mail.sendmailSetuidWrapper = {
        group = "root";
        owner = "root";
        permissions = "u+rx,g+x,o+x";
        program = "sendmail";
        setgid = false;
        setuid = false; };

    })
  ];
}
