{ config, lib, pkgs, ... }:

with lib;
let

  fclib = import ../lib;

in {

  config = {

    system.activationScripts.haproxy = ''
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
        unit_configs_merged = zipAttrsWith (name: values: (last values)) unit_configs;
      in
        unit_configs_merged;

  };

}
