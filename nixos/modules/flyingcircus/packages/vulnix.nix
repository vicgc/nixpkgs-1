{ pkgs, ...  }:

let
  url = https://github.com/flyingcircusio/vulnix/archive/047185d9.tar.gz;
in
import (builtins.fetchTarball url) { inherit pkgs; }
