{ config, lib, pkgs, ... }:

# Flying Circus user management
#
# UID ranges
#
# 30.000 - 30.999: reserved for nixbldXX and NixOS stuff
# 31.000 - 65.534: reserved for Flying Circus-specific system user
#
#
# GID ranges
#
# 30.000 - 31.000: reserved for NixOS-specific stuff
# 31.000 - 65.534: reserved for Flying Circus-specific system groups

let

  cfg = config.flyingcircus;

  get_primary_group = user:
    builtins.getAttr user.class {
      human = "users";
      service = "service";
    };

  # Data read from Directory (list) -> users.users structure (list)
  map_userdata = users:
    lib.listToAttrs
      (map
        (user: {
          name = user.uid;
          value = {
            description = user.name;
            group = get_primary_group user;
            hashedPassword = lib.removePrefix "{CRYPT}" user.password;
            home = user.home_directory;
            isNormalUser = true;
            openssh.authorizedKeys.keys = user.ssh_pubkey;
            shell = "/run/current-system/sw${user.login_shell}";
            uid = user.id;
          };
        })
      users);

  admins_group =
    lib.optionalAttrs
      (cfg.admins_group_data != {})
      { ${cfg.admins_group_data.name}.gid = cfg.admins_group_data.gid; };

  current_rg =
    if lib.hasAttrByPath ["parameters" "resource_group"] cfg.enc
    then cfg.enc.parameters.resource_group
    else null;

  get_group_memberships_for_user = user:
    if current_rg != null && builtins.hasAttr current_rg user.permissions
    then
      lib.listToAttrs
        (map
          # making members a scalar here so that zipAttrs automatically joins
          # them but doesn't create a list of lists.
          (perm: { name = perm; value = { members = user.uid; }; })
          (builtins.getAttr current_rg user.permissions))
    else {};

  # user list from directory -> { groupname.members = [a b c], ...}
  get_group_memberships = users:
    lib.mapAttrs (name: groupdata: lib.zipAttrs groupdata)
      (lib.zipAttrs (map get_group_memberships_for_user users));

  get_permission_groups = permissions:
    lib.listToAttrs
      (builtins.filter
        (group: group.name != "wheel")  # This group already exists
        (map
          (permission: {
            name = permission.name;
            value = {
              gid = config.ids.gids.${permission.name};
            };
          })
          permissions));

  home_dir_permissions = userdata:
    map
      (user: "install -d -o ${toString user.id} -g ${get_primary_group user} -m 0755 ${user.home_directory}")
      userdata;

  configure_lingering = userdata:
    # No users should have lingering enabled
    map
      (user: " ${config.systemd.package}/bin/loginctl disable-linger ${user.uid}")
      userdata;

  # merge a list of sets recursively
  mergeSets = listOfSets:
    if (builtins.length listOfSets) == 1 then
      builtins.head listOfSets
    else
      lib.recursiveUpdate
        (builtins.head listOfSets)
        (mergeSets (builtins.tail listOfSets));

in

{
  config = {

    security.pam.services.sshd.showMotd = true;
    security.pam.access = ''
    # Local logins are always fine. This is to unblock any automation like
    # systemd services
    + : ALL : LOCAL
    # Remote logins are restricted to admins and the login group.
    + : root (admins) (login): ALL
    # Other remote logins are not allowed.
    - : ALL : ALL
    '';

    users = {
      mutableUsers = false;
      users = map_userdata cfg.userdata;
      groups = mergeSets [
        admins_group
        { service.gid = config.ids.gids.service; }
        (get_group_memberships cfg.userdata)
        (get_permission_groups cfg.permissionsdata)
        ];
    };

    # needs to be first in sudoers because of the %admins rule
    security.sudo.extraConfig = lib.mkBefore ''
      Defaults set_home,!authenticate,!mail_no_user
      Defaults lecture = never

      # Allow unrestricted access to super admins
      %admins ALL=(ALL) PASSWD: ALL

      ## Cmnd alias specification
      Cmnd_Alias  REBOOT = ${pkgs.systemd}/bin/systemctl reboot, \
            ${pkgs.systemd}/bin/systemctl poweroff

      %sudo-srv ALL=(%service) ALL
      %sudo-srv ALL=(root) REBOOT

      # Allow applying config and restarting services to service users
      Cmnd_Alias  SYSTEMCTL = ${pkgs.systemd}/bin/systemctl
      %sudo-srv ALL=(root) SYSTEMCTL
      %service  ALL=(root) SYSTEMCTL
    '';

    system.activationScripts.fcio-homedirpermissions = lib.stringAfter [ "users" ]
      (builtins.concatStringsSep "\n" (home_dir_permissions cfg.userdata));

    system.activationScripts.fcio-configure-lingering = lib.stringAfter [ "users" ]
      (builtins.concatStringsSep "\n" (configure_lingering cfg.userdata));

  };
}
