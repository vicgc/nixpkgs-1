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
    let

    {
      imports = [ ../static/default.nix
                  ../roles/default.nix
                  ../services/default.nix
                  ../packages/default.nix
                  ../platform/default.nix
                   ];

      flyingcircus.userdata_path = ./users.json;
      flyingcircus.admins_group_path = ./admins.json;
      flyingcircus.permissions_path = ./permissions.json;

        # [{"login_shell": "/bin/bash", "uid": "bob", "home_directory": "/home/bob", "name": "Bob the Blob", "ssh_pubkey": ["ssh-rsa asdf bob"], "permissions": {"test": ["stats", "sudo-srv", "login", "admins"]}, "password": "{CRYPT}$6$FrY8Rmj2$asdffdsa", "gid": 100, "id": 1152, "class": "human"}]

      swapDevices = mkOverride 0
        [ { device = "/root/swapfile"; size = 128; } ];

      systemd.tmpfiles.rules = [ "d /tmp 1777 root root 10d" ];
      fileSystems = mkVMOverride { "/tmp2" =
        { fsType = "tmpfs";
          options = "mode=1777,noauto";
        };
      };
      systemd.automounts = singleton
        { wantedBy = [ "multi-user.target" ];
          where = "/tmp2";
        };
    };


  testScript = ''

    $machine->waitForUnit("default.target");

    subtest "admin-user", sub {
      # check for user existence
      $machine->succeed("id zagy");
      $machine->screenshot("asdf");
    };

  '';
})
