# Generic configuration options to reduce bootup time on VM tests
{ lib, ... }:
{
  config = {
    flyingcircus.enc.parameters.resource_group = "test";
    flyingcircus.ssl.generate_dhparams = false;
    networking.useDHCP = lib.mkForce false;
    security.rngd.enable = false;
    virtualisation.vlans = [];
  };
}

# Example usage:
#
# import ../../../tests/make-test.nix ({
#   pkgs
# , lib
# , ...
# }:
# {
#   name = "...";
#   nodes = {
#     master =
#       { pkgs, config }:
#       {
#         imports = [
#           ./setup.nix
#           ...
#         ];
#       };
#   };
#   testScript = ''
#     ...
#   '';
# })
