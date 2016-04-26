{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.flyingcircus;

  userSuppliedFiles =
    builtins.filter
      (name: hasSuffix ".service" name)
      (builtins.attrNames localConfig);

  localConfig =
      if pathExists /etc/local/systemd
      then builtins.readDir /etc/local/systemd
      else {};

in
{

  system.activationScripts.flyingcircus_systemd = ''
    install -d -g service  -m 02775 /etc/local/systemd
  '';

  environment.etc =
    {
      "local/systemd/README.txt".text = ''
        systemdunits bla bla
      '';
    } //
    (builtins.listToAttrs
      (map (
        name: {
          name = "systemd/system/${name}";
          value = {
            source = "/etc/local/systemd/${name}";
          };
        })
        userSuppliedFiles));
}

# The other non-working implementation

# { config, lib, pkgs, ... }:

# with lib;
# let
#   cfg = config.flyingcircus;

#   userSuppliedConfig =
#     builtins.listToAttrs
#       (map
#        (filename: {
#           name = removeSuffix ".json" filename;
#           value =
#             builtins.fromJSON (builtins.readFile "/etc/local/systemd/${filename}")
#             // { path = [ "foo/bar/baz" ]; };
#         })
#        userSuppliedFiles);

#   userSuppliedFiles =
#     builtins.filter
#       (name: hasSuffix ".json" name)
#       (builtins.attrNames localConfig);

#   localConfig =
#       if pathExists /etc/local/systemd
#       then builtins.readDir /etc/local/systemd
#       else {};

# in
# {

#   system.activationScripts.flyingcircus_systemd = ''
#     install -d -g service  -m 02775 /etc/local/systemd
#   '';

#   systemd.services = userSuppliedConfig;

# }
