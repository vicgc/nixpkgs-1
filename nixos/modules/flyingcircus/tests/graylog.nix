import ../../../tests/make-test.nix ({ lib, pkgs, ... }:
{
  name = "graylog";
  machine =
    { config, ... }:
    {
      imports = [
        ./setup.nix
        ../platform
        ../roles
        ../services
        ../static
      ];

      virtualisation.memorySize = 4096;

      flyingcircus.roles.loghost.enable = true;
      networking.domain = "local";
      flyingcircus.enc.parameters.directory_password = "asdf";
      flyingcircus.enc.parameters.resource_group = "test";
      flyingcircus.enc_addresses.srv = [
        {
         "ip" = "127.0.0.1/24";
         "mac" = "02:00:00:03:13:5B";
         "name" = "machine";
         "rg" = "test";
         "ring" = 1;
         "vlan" = "srv";
        }
      ];
      users.groups.login = {
        members = [];
      };
      flyingcircus.enc_services = [
        { service = "loghost-server";
          address = "machine.local";
        }
      ];
      networking.extraHosts = ''
        127.0.0.1 machine.local
      '';

    };
  testScript = ''
    $machine->waitForUnit("nginx.service");
    $machine->waitForUnit("haproxy.service");
    $machine->waitForUnit("graylog.service");
    $machine->waitForUnit("mongodb.service");
    $machine->waitForUnit("elasticsearch.service");
  '';
})
