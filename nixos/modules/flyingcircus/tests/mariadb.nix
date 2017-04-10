import ../../../tests/make-test.nix ({ pkgs, ... }:
{
  name = "mariadb";

  nodes = {
    master =
      { pkgs, config, ... }:
      let
        insertSql = pkgs.writeScript "test-sql" ''
          create table employees
          ( Id   INTEGER      NOT NULL,
            Name VARCHAR(255) NOT NULL,
            primary key(Id)
          );

          insert into employees values (1, 'John Doe');
        '';
      in
       {
        imports = [
          ./setup.nix
          ../platform
          ../roles/postgresql.nix
          ../services/fcmanage.nix
          ../services/sensu/client.nix
          ../static
        ];

        services.mysql.enable = true;
        services.mysql.initialDatabases = [ { name = "employees"; schema = insertSql;}];
        services.mysql.package = pkgs.mariadb;
      };
  };

  testScript =
    ''
      $master->waitForUnit("mysql.service");
      $master->sleep(10);
      $master->succeed("echo 'use employees; select * from employees' | mysql -u root -N | grep -5 \"John Doe\"");
    '';
})
