# Generic configuration options to reduce bootup time on VM tests
{ lib, ... }:
{
  config = {
    flyingcircus.agent.enable = false;
    flyingcircus.enc.parameters.resource_group = "test";
    flyingcircus.ssl.generate_dhparams = false;
    networking.useDHCP = lib.mkForce false;
    security.rngd.enable = false;
    virtualisation.vlans = [];
  };
}

# Example usage:
#
# import ../../../tests/make-test.nix ({ ... }:
# {
#   name = "...";
#   nodes = {
#     vm =
#       { pkgs, config, ... }:
#       {
#         imports = [
#           ./setup.nix
#           ../platform
#           ../roles
#           ../services
#           ../static
#         ];
#         config.option = ...;
#       };
#   };
#   # see https://nixos.org/nixos/manual/index.html#sec-writing-nixos-tests
#   testScript = ''
#     $vm->waitForUnit("...");
#     $vm->succeed("...") =~ /.../;
#     ...
#   '';
# })
