import ../../../tests/make-test.nix ({ pkgs
, lib
, mysql55 ? false
, mysql56 ? false
, mysql57 ? false
, ... }:
{
  name = "mysql";

  nodes = {
    master =
      { pkgs, config, ... }:
      {
        virtualisation.memorySize = 2048;

        imports = [
          ./setup.nix
          ../static/default.nix
          ../roles/default.nix
          ../services/default.nix
          ../platform/default.nix
        ];

        flyingcircus.ssl.generate_dhparams = false;
        flyingcircus.roles.mysql55.enable = mysql55;
        flyingcircus.roles.mysql56.enable = mysql56;
        flyingcircus.roles.mysql57.enable = mysql57;

        # Tune those arguments as we'd like to run this on Hydra
        # in a rather small VM.
        flyingcircus.roles.mysql.extraConfig = ''
            [mysqld]
            innodb-buffer-pool-size         = 10M
            innodb_log_file_size            = 10M
        '';

      };
  };

  testScript = ''
    startAll;

    $master->waitForUnit("mysql");
    $master->sleep(1);
    $master->succeed("mysqladmin ping");
    $master->succeed("mysql mysql -e 'select * from user' > /dev/null");
  '';
})
