{ options, config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.grafana;
  fclib = import ../lib;

  b2s = val: if val then "true" else "false";

  envOptions = {
    PATHS_DATA = cfg.dataDir;
    PATHS_PLUGINS = "${cfg.dataDir}/plugins";
    PATHS_LOGS = "${cfg.dataDir}/log";

    SERVER_PROTOCOL = cfg.protocol;
    SERVER_HTTP_ADDR = cfg.addr;
    SERVER_HTTP_PORT = cfg.port;
    SERVER_DOMAIN = cfg.domain;
    SERVER_ROOT_URL = cfg.rootUrl;
    SERVER_STATIC_ROOT_PATH = cfg.staticRootPath;
    SERVER_CERT_FILE = cfg.certFile;
    SERVER_CERT_KEY = cfg.certKey;

    DATABASE_TYPE = cfg.database.type;
    DATABASE_HOST = cfg.database.host;
    DATABASE_NAME = cfg.database.name;
    DATABASE_USER = cfg.database.user;
    DATABASE_PASSWORD = cfg.database.password;
    DATABASE_PATH = cfg.database.path;

    SECURITY_ADMIN_USER = cfg.security.adminUser;
    SECURITY_ADMIN_PASSWORD = cfg.security.adminPassword;
    SECURITY_SECRET_KEY = cfg.security.secretKey;

    USERS_ALLOW_SIGN_UP = b2s cfg.users.allowSignUp;
    USERS_ALLOW_ORG_CREATE = b2s cfg.users.allowOrgCreate;
    USERS_AUTO_ASSIGN_ORG = b2s cfg.users.autoAssignOrg;
    USERS_AUTO_ASSIGN_ORG_ROLE = cfg.users.autoAssignOrgRole;

    AUTH_ANONYMOUS_ENABLE = b2s cfg.auth.anonymous.enable;
    AUTH_ANONYMOUS_ORG_NAME = cfg.auth.anonymous.org_name;
    AUTH_ANONYMOUS_ORG_ROLE = cfg.auth.anonymous.org_role;

    ANALYTICS_REPORTING_ENABLED = b2s cfg.analytics.reporting.enable;
  } // cfg.extraOptions;

in {
  options.services.grafana = {

    auth.anonymous = {

      org_name = mkOption {
        description = "Which organization to allow anonymous access to";
        default = "Main Org.";
        type = types.str;
      };
      org_role = mkOption {
        description = "Which role anonymous users have in the organization";
        default = "Viewer";
        type = types.str;
      };

    };

    analytics.reporting = {
      enable = mkOption {
        description = "Whether to allow anonymous usage reporting to stats.grafana.net";
        default = true;
        type = types.bool;
      };
    };
  };

  config = mkIf cfg.enable {

    systemd.services.grafana = {
      environment = mkForce (
          mapAttrs' (n: v: nameValuePair "GF_${n}" (toString v)) envOptions);
      serviceConfig = {
        ExecStart = mkForce "${cfg.package.bin}/bin/grafana-server -homepath ${cfg.dataDir}";
      };
      preStart = mkForce ''
        ${pkgs.coreutils}/bin/ln -fs ${cfg.package}/share/grafana/conf ${cfg.dataDir}
        ${pkgs.coreutils}/bin/ln -fs ${cfg.package}/share/grafana/vendor ${cfg.dataDir}
      '';
    };

  };
}
