{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.rabbitmq;

  plugins = pkgs.stdenv.mkDerivation {
    name = "rabbitmq_server_plugins";
    builder = builtins.toFile "makePlugins.sh" ''
      source $stdenv/setup
      mkdir -p $out
      ln -s $server/plugins/* $out
      for package in $packages
      do
        ln -s $package/* $out
      done
    '';
    server = pkgs.rabbitmq_server;
    packages = cfg.pluginPackages;
    preferLocalBuild = true;
    allowSubstitutes = false;
  };

in {

  config = mkIf cfg.enable {
    systemd.services.rabbitmq.environment = {
        RABBITMQ_PLUGINS_DIR = plugins;
    };
  };
}
