import ../../../tests/make-test.nix ({ pkgs, ... }: {
  name = "influxdb";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ chaoflow offline ];
  };

  nodes = {
    one = { config, pkgs, ... }: {
      imports = [
        ./setup.nix
        ../services/influxdb1_2.nix
        ../static ];
      services.influxdb1_2.enable = true;
    };
  };

  testScript = ''
    startAll;

    $one->waitForUnit("influxdb.service");

    # create database
    $one->succeed(q~
      curl -XPOST http://localhost:8086/query --data-urlencode "q=CREATE DATABASE test"
    ~);
    # write some points and run simple query
    $one->succeed(q~
      curl -XPOST 'http://localhost:8086/write?db=test' --data-binary 'cpu_load_short,host=server01,region=us-west value=0.64 1434055562000000000'
    ~);
    $one->succeed(q~
      curl -GET 'http://localhost:8086/query' --data-urlencode "db=test" --data-urlencode "q=SELECT \"value\" FROM \"cpu_load_short\" WHERE \"region\"='us-west'"  | grep "0\.64"
    ~);
  '';
})
