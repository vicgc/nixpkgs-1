#!/bin/sh
set -x
NIX_PATH="nixpkgs=$(dirname $0)/../../../../../"
rm -f Gemfile.lock
rm -rf /tmp/bundix
nix-shell -p git -p stdenv -p stdenv -p cacert -p bundler -p openssl --command "bundler package --no-install --path /tmp/bundix/bundle"
nix-shell -p bundix --command bundix
