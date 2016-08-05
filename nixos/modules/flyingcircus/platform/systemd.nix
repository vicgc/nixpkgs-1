# Configure systemd journal access and local units.
{ lib, pkgs, ... }:

with lib;
let
  fclib = import ../lib;

in {
  config = {

    services.journald.extraConfig = ''
      SystemMaxUse=1G
      MaxLevelConsole=notice
      ForwardToSyslog=true
    '';

    system.activationScripts.systemd-journal-acl = ''
      # Ensure journal access for all users.
      ${pkgs.acl}/bin/setfacl -R --remove-all /var/log/journal
      chmod -R a+rX /var/log/journal
    '';

    system.activationScripts.systemd-local = ''
      install -d -o root -g service -m 02775 /etc/local/systemd
    '';

    systemd.units =
      let
        unit_files = if (builtins.pathExists "/etc/local/systemd")
          then fclib.filesRel "/etc/local/systemd" else [];
        unit_configs = map
          (file: { "${file}" =
             { text = readFile ("/etc/local/systemd/" + file);
               wantedBy = [ "multi-user.target" ];};})
          unit_files;
      in zipAttrsWith (name: values: (last values)) unit_configs;

  };
}
