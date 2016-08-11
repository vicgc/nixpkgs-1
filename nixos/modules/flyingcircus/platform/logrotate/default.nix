{ config, lib, pkgs, ... }: with lib;


let

  cfg = config;

  localConfig = if pathExists /etc/local/logrotate
    then "${/etc/local/logrotate}"
    else null;

  globalOptions = ''
      # Global default options for the Flying Circus platform.
      daily
      rotate 14
      create
      dateext
      delaycompress
      compress
      notifempty
      nomail
      noolddir
      missingok
      sharedscripts
  '';

  users = attrValues cfg.users.users;
  service_users = builtins.filter
    (user: user.group == "service" || user.group == "vagrant")
    users;

in

{

  config = {

    services.logrotate.enable = true;
    services.logrotate.config = mkOrder 50 globalOptions;

    environment.etc = {
      "local/logrotate/README.txt".text = ''
        logrotate is enabled on this machine.

        You can put your application-specific logrotate snippets here
        and they will be executed regularly within the context of the
        owning user.

        The files must be placed in each service user's directory.

        /etc/local/logrotate/s-myapp/myapp
        /etc/local/logrotate/s-otherapp/something
        /etc/local/logrotate/s-serviceuser/somethingelse

        We will also apply the following basic options by default:

        ${globalOptions}
       '';
      "logrotate.options".text = globalOptions;
    };

    # We create one directory for each service user. I decided not to remove
    # old directories as this may be manually placed data that I don't want
    # to delete accidentally.
    system.activationScripts.logrotate-user = stringAfter [ "users" ]
    ''
      # Enable service users to place logrotate snippets.
      install -d -o root -g root -m 0755 /etc/local/logrotate
      ${builtins.concatStringsSep "\n"
        (map
          (user: ''
            install -d -m 0755 -o ${user.name} -g service /etc/local/logrotate/${user.name}
            '')
          service_users)}
      install -d -o root -g service -m 02775 /var/spool/logrotate
    '';

    systemd.services = let
      units = map (user:
        { "${user.name}-logrotate" = {
          description   = "Logrotate Service for ${user.name}";
          wantedBy      = [ "multi-user.target" ];
          startAt       = "*-*-* 00:05:00";

          path = [ pkgs.bash pkgs.logrotate ];

          serviceConfig.User = "${user.name}";
          serviceConfig.Restart = "no";
          serviceConfig.ExecStart = "${./user-logrotate.sh} ${localConfig}";
          };
        }) service_users;
      units_merged = zipAttrsWith (name: values: (last values)) units;
      in
        mkIf (localConfig != null) units_merged;

  };

}
