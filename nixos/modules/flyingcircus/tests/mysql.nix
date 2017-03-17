{ system, hydraJob }:
let
  testFactory = version: (hydraJob (mysqlTest version { inherit system; }));

  mysqlTest = version:
  import ../../../tests/make-test.nix ({...}:
  {
    name = "mysql-${version}";

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

        flyingcircus.roles.${version}.enable = true;

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
  });

in
{
  mysql_5_5 = testFactory "mysql55";
  mysql_5_6 = testFactory "mysql56";
  mysql_5_7 = testFactory "mysql57";
}
