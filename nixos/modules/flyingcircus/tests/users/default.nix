# Test that the user generation from ENC works fine.

import ../../../../tests/make-test.nix ({ ... } :
{
  name = "users";

  machine =
    { config, lib, pkgs, modulesPath, ... }:
    with lib;
    {
      imports = [
        ../setup.nix
        ../../static/default.nix
        ../../roles/default.nix
        ../../services/default.nix
        ../../platform/default.nix
      ];

      environment.systemPackages = [ pkgs.shadow ];

      flyingcircus.load_enc = false;
      flyingcircus.userdata_path = ./users.json;
      flyingcircus.admins_group_path = ./admins.json;
      flyingcircus.permissions_path = ./permissions.json;
    };

  testScript = ''
    $machine->waitForUnit("default.target");

    subtest "admin-user", sub {
      # check for group memberships
      $machine->succeed("test \"`id foo`\" = \"uid=1000(foo) gid=100(users) groups=500(login),503(sudo-srv),2003(admins),100(users)\"");
      # ssh key exists
      $machine->succeed("test \"`cat /etc/ssh/authorized_keys.d/foo`\" = 'ssh-ed25519 some_hash foo\@computer'>/dev/console");
      # password is set
      $machine->succeed("passwd --status foo | grep -v NP -q");

    };
    subtest "memberships", sub {
      # group memberships
      # - member of login
      $machine->succeed("test \"`id foo2`\" = \"uid=1001(foo2) gid=100(users) groups=500(login),100(users)\"");
      # - member of admins
      $machine->succeed("test \"`id foo3`\" = \"uid=1002(foo3) gid=100(users) groups=2003(admins),100(users)\"");
      # - member of sudo-srv
      $machine->succeed("test \"`id foo4`\" = \"uid=1003(foo4) gid=100(users) groups=503(sudo-srv),100(users)\"");
      # - member of any groups
      $machine->succeed("test \"`id foo5`\" = \"uid=1004(foo5) gid=100(users) groups=100(users)\"");
    };
  '';
})
