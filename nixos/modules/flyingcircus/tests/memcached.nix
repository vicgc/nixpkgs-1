import ../../../tests/make-test.nix ({ ... }:
{
  name = "memcached";

  nodes = {
    srv1 =
      { pkgs, config, ... }:
      {
        imports = [
          ./setup.nix
          ../static
          ../roles
          ../services
          ../platform
        ];

        services.memcached.enable = true;
      };
  };

  testScript = ''
    startAll;
    $srv1->waitForUnit('memcached');

    $srv1->succeed(<<'__SHELL__');
    set -e
    echo -e 'add my_key 0 60 11\r\nhello world\r\nquit' | nc localhost 11211 | \
      grep STORED
    echo -e 'get my_key\r\nquit' | nc localhost 11211 | grep 'hello world'
    __SHELL__
  '';
})
