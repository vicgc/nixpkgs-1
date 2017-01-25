import ../../../tests/make-test.nix ({ rolename, pkgs, ... }:
{
  name = rolename;
  machine =
    { pkgs, config, ... }:
    {
      imports = [
        ./setup.nix
        ../platform
        ../roles/postgresql.nix
        ../services/fcmanage.nix
        ../services/sensu/client.nix
        ../static
      ];

      config.flyingcircus.roles.${rolename}.enable = true;
    };
  testScript =
    let
      insertSql = pkgs.writeText "insert.sql" ''
        CREATE TABLE employee (
          id INT PRIMARY KEY,
          name TEXT
        );
        INSERT INTO employee VALUES (1, 'John Doe');
      '';

      selectSql = pkgs.writeText "select.sql" ''
        SELECT * FROM employee WHERE id = 1;
      '';

      dataTest = pkgs.writeScript "postgresql-tests" ''
        createdb employees
        psql --echo-all -d employees < ${insertSql}
        psql --echo-all -d employees < ${selectSql} | grep -5 "John Doe"
      '';
    in
    ''
      $machine->waitForUnit("postgresql.service");

      # simple data round trip
      $machine->succeed('sudo -u postgres -- sh ${dataTest}');

      # should not trust connections via TCP
      $machine->fail('psql --no-password -h localhost -l');
    '';
})
