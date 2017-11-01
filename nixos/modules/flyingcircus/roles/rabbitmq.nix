{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.flyingcircus.roles.rabbitmq;
  fclib = import ../lib;
  # XXX: We choose the first IP of ethsrv here, as the service is not capable
  #      of handling more than one IP.
  listen_address = builtins.elemAt ( fclib.listenAddresses config "ethsrv" ) 0;
  extraConfig = (fclib.configFromFile /etc/local/rabbitmq/rabbitmq.config "");

  # Derive password for telegraf.
  telegrafPassword = builtins.hashString
    "sha256" (concatStrings [
      config.flyingcircus.enc.parameters.directory_password
      config.networking.hostName
      "telegraf"
    ]);

in
{

  options = {
    flyingcircus.roles.rabbitmq = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Flying Circus RabbitMQ role.";
      };

    };
  };

  config = mkIf cfg.enable {

    services.rabbitmq.enable = true;
    services.rabbitmq.listenAddress = listen_address;
    services.rabbitmq.plugins = [ "rabbitmq_management" ];
    services.rabbitmq.config = extraConfig;

    users.extraUsers.rabbitmq = {
      shell = "/run/current-system/sw/bin/bash";
    };

    security.sudo.extraConfig = ''
      # Service users may switch to the rabbitmq system user
      %sudo-srv ALL=(rabbitmq) ALL
      %service ALL=(rabbitmq) ALL
      # We need this for sensu checks
      # %sensuclient ALL=(rabbitmq) ALL
    '';

    # We use this in this way in favor of setting PermissionsStartOnly to
    # true as other script expect running as rabbitmq user
    system.activationScripts.fcio-rabbitmq = ''
      install -d -o ${toString config.ids.uids.rabbitmq} -g service -m 02775 \
        /etc/local/rabbitmq/
    '';

    environment.etc."local/rabbitmq/README.txt".text = ''
        RabbitMQ (${pkgs.rabbitmq_server.version}) is running on this machine.

        If you need to set non-default configuration options, you can put a
        file called rabbitmq.config into this directory. The content of this
        file will be added the configuration of the RabbitMQ-service.

        To access rabbitmqctl and other management tools, change into rabbitmq's
        user and run your command(s). Example:

        $ sudo -iu rabbitmq
        % rabbitmqctl status

      '';

    systemd.services.fc-rabbitmq-settings = {
      description = "Prepare rabbitmq for operation in FC.";
      requires = [ "rabbitmq.service" ];
      after = ["rabbitmq.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.rabbitmq_server pkgs.curl ];
      serviceConfig = {
        Type = "oneshot";
        User = "rabbitmq";
        RemainAfterExit = true;
      };

      script =
        let
          curl = ''
            curl -s -H "content-type:application/json" \
          '';
          api = "http://localhost:15672/api";
        in ''
          # Delete user guest, if it's there with default password, and
          # administrator privileges.
          ${curl} -XDELETE -u guest:guest ${api}/users/guest >/dev/null

          # Create user for telegraf, it it does not exist
          ${curl} -u fc-telegraf:${telegrafPassword} -f \
            ${api}/overview >/dev/null || \
              rabbitmqctl add_user fc-telegraf ${telegrafPassword}

          rabbitmqctl set_user_tags fc-telegraf monitoring || true
          for vhost in $(rabbitmqctl list_vhosts -q); do
            rabbitmqctl set_permissions fc-telegraf -p "$vhost" "" "" ".*"
          done
        '';
    };

    systemd.timers.fc-rabbitmq-settings = {
      description = "Timer for preparing rabbitmq regularly.";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Unit = "fc-rabbitmq-settings";
        OnUnitActiveSec = "1h";
        AccuracySec = "10m";
      };
    };

    services.telegraf.inputs = {
      rabbitmq = [{
        url = "http://${config.networking.hostName}:15672";
        username = "fc-telegraf";
        password = telegrafPassword;
        nodes = [ "rabbit@${config.networking.hostName}" ];
      }];
    };

  };

}
