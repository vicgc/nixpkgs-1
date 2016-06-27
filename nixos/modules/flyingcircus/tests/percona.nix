import <nixpkgs/nixos/tests/make-test.nix> ({
    pkgs
    ,percona
    ,...} : {
  name = "percona";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ theuni ];
  };

  nodes = {
    master =
      { pkgs, config, ... }:

      {
        virtualisation.memorySize = 2048;

        imports = [ ../static/default.nix
                    ../roles/default.nix
                    ../services/default.nix
                    ../packages/default.nix
                    ../platform/default.nix ];

        flyingcircus.ssl.generate_dhparams = false;
        flyingcircus.roles.mysql.enable = true;
        flyingcircus.roles.mysql.package = percona;

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
