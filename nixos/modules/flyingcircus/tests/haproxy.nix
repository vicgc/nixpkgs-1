import ../../../tests/make-test.nix ({ pkgs, ... }:
{
  name = "haproxy";
  nodes = {
    haproxyVM =
      { config, lib, ... }:
      {
        imports = [
          ./setup.nix
          ../platform
          ../roles
          ../services
          ../static
        ];
        config.flyingcircus.roles.haproxy.enable = true;
        config.services.haproxy.config = lib.mkForce ''
          defaults
            mode http
            timeout connect 5s
            timeout client 5s
            timeout server 5s

          frontend http-in
            bind *:8888
            default_backend server

          backend server
            server python-http 127.0.0.1:7000
        '';
      };
  };
  testScript = ''
    $haproxyVM->start;
    $haproxyVM->execute(<<__SETUP__);
    echo 'Hello World!' > hello.txt
    ${pkgs.python3.interpreter} -m http.server 7000 &
    __SETUP__

    $haproxyVM->waitForUnit("haproxy");
    $haproxyVM->succeed(<<__TEST__) =~ /Hello World!/;
    # request goes through haproxy
    curl -s http://localhost:8888/hello.txt
    __TEST__
  '';
})

