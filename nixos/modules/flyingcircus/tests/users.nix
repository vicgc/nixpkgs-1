# Test that the user generation from ENC works fine.

import <nixpkgs/nixos/tests/make-test.nix> ({ pkgs, ...} :
{
  name = "users";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ theuni ];
  };

  machine =
    { config, lib, pkgs, modulesPath, ... }:
    with lib;

    {
      imports = [ ../static/default.nix
                  ../roles/default.nix
                  ../services/default.nix
                  ../packages/default.nix
                  ../platform/default.nix
                   ];
      flyingcircus.ssl.generate_dhparams = false;

      flyingcircus.load_enc = false;
      flyingcircus.userdata_path = ./data/users.json;
      flyingcircus.admins_group_path = ./data/admins.json;
      flyingcircus.permissions_path = ./data/permissions.json;

      flyingcircus.enc.parameters.resource_group = "test";
      security.rngd.enable = false;
      virtualisation.vlans = [];
      networking.useDHCP = mkForce false;

    };


  testScript = ''

    $machine->waitForUnit("default.target");

    subtest "admin-user", sub {
      # check for group memberships
      $machine->succeed("test \"`id zagy`\" = \"uid=1000(zagy) gid=100(users) groups=500(login),503(sudo-srv),2003(admins),100(users)\"")
    };

  '';
})
