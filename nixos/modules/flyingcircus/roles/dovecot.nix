{ config, lib, pkgs, ... }:
with builtins;

let
  cfg = config.flyingcircus;
  fclib = import ../lib;

in
{
  options = {

    flyingcircus.roles.dovecot = {
      enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable the Flying Circus dovecot server role.";
      };
    };

  };

  config = lib.mkIf cfg.roles.dovecot.enable {

    services.dovecot2 =
    let
      localConfigs =
        filter (lib.hasSuffix ".conf") (fclib.filesRel "/etc/local/dovecot");

    in
    {
      enable = true;
      extraConfig = lib.concatStrings
        (map
          (file: "!include ${/etc/local/dovecot + "/${file}"}\n")
          localConfigs);
    };

    environment.etc."local/dovecot/README".text = ''
      Dovecot local configuration

      Files matching *.conf will be included in Dovecot's configuration. Please
      run fc-manage to update configs and restart dovecot.
    '';

    system.activationScripts.dovecot = ''
      install -d -g service -m 0775 /etc/local/dovecot
    '';

  };
}
