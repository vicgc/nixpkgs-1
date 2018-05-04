import ../../../tests/make-test.nix ({ rolename, ... }:
{
  name = rolename;

  nodes = {
    master =
      { pkgs, config, ... }:
      {

        imports = [
          ./setup.nix
          ../static
          ../roles
          ../services
          ../platform
        ];

        virtualisation.memorySize = 2048;
        flyingcircus.roles.${rolename}.enable = true;

      };
  };

  testScript = ''
    startAll;

    $master->waitForUnit("elasticsearch");

    # cluster healthy?
    $master->succeed('curl -s "localhost:9200/_cat/health?v" | grep green');

    # simple data round trip
    $master->succeed(<<'__EOF__');
      set -e
      echo -e '\nCreating index'
      curl -s -XPUT 'localhost:9200/customer'
      curl -s 'localhost:9200/_cat/indices?v'

      echo -e '\nSubmitting data'
      curl -s -XPUT 'localhost:9200/customer/external/1' \
        -d'{ "name": "John Doe" }'

      echo -e '\nRetrieving data'
      curl -s 'localhost:9200/customer/external/1' | grep 'John Doe'
    __EOF__
  '';
})
