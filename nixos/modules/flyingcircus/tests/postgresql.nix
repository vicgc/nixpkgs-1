import ../../../tests/make-test.nix ({ rolename, lib, pkgs, ... }:
{
  name = rolename;
  machine =
    { config, ... }:
    {
      imports = [
        ./setup.nix
        ../static
        ../roles
        ../services
        ../platform
      ];

      config.flyingcircus = {
        roles.${rolename}.enable = true;

        # postgresql.conf depends on srv addresses
        enc.parameters.interfaces.srv = {
          bridged = false;
          mac = "52:54:00:12:34:56";
          networks = {
            "192.168.101.0/24" = [ "192.168.101.1" ];
            "2001:db8:f030:1c3::/64" = [ "2001:db8:f030:1c3::1" ];
          };
          gateways = {};
        };
      };
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

      createExtensions = pkgs.writeScript "rum-tests" ''
        psql employees -c "CREATE EXTENSION rum;"
      '';
    in
    ''
      $machine->waitForUnit("postgresql.service");

      # simple data round trip
      $machine->succeed('sudo -u postgres -- sh ${dataTest}');

      # should not trust connections via TCP
      $machine->fail('psql --no-password -h localhost -l');
    '' +
      lib.optionalString  (lib.strings.versionAtLeast rolename "postgresql96")
    ''# do the rum extension test
      $machine->succeed('sudo -u postgres -- sh ${createExtensions}');
    '';
})
