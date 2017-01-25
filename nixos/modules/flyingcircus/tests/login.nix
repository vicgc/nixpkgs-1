import ../../../tests/make-test.nix ({ pkgs, ... }:

{
  name = "login";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ eelco chaoflow ];
  };

  machine = { ... }: { };

  testScript =
    ''
      $machine->waitForUnit('multi-user.target');
      $machine->waitUntilSucceeds("pgrep -f 'agetty.*tty1'");
      $machine->screenshot("postboot");

      subtest "create user", sub {
          $machine->succeed("useradd -m alice");
          $machine->succeed("(echo foobar; echo foobar) | passwd alice");
      };

      # Check whether switching VTs works.
      subtest "virtual console switching", sub {
          $machine->fail("pgrep -f 'agetty.*tty2'");
          $machine->sendKeys("alt-f2");
          $machine->waitUntilSucceeds("[ \$(fgconsole) = 2 ]");
          $machine->waitForUnit('getty@tty2.service');
          $machine->waitUntilSucceeds("pgrep -f 'agetty.*tty2'");
      };

      # Log in as alice on a virtual console.
      subtest "virtual console login", sub {
          $machine->sleep(2); # urgh: wait for username prompt
          $machine->sendChars("alice\n");
          $machine->waitUntilSucceeds("pgrep login");
          $machine->sleep(1); # urgh: wait for `Password:'
          $machine->sendChars("foobar\n");
          $machine->waitUntilSucceeds("pgrep -u alice bash");
          $machine->sendChars("touch done\n");
          $machine->waitForFile("/home/alice/done");
      };

      # Log out.
      subtest "virtual console logout", sub {
          $machine->sendChars("exit\n");
          $machine->waitUntilFails("pgrep -u alice bash");
          $machine->screenshot("mingetty");
      };

      # Check whether ctrl-alt-delete works.
      subtest "ctrl-alt-delete", sub {
          $machine->sendKeys("ctrl-alt-delete");
          $machine->waitForShutdown;
      };
    '';

})
