{ pkgs ? import <nixpkgs> { }
, stdenv ? pkgs.stdenv
, lib ? pkgs.lib
, fetchurl ? pkgs.fetchurl
}:


stdenv.mkDerivation rec {
  name = "rabbitmq_delayed_message_exchange-${version}";
  version = "0.0.1";

  src = fetchurl {
    url = "http://www.rabbitmq.com/community-plugins/v3.4.x/rabbitmq_delayed_message_exchange-${version}-rmq3.4.x-9bf265e4.ez";
    sha256 = "10vfcs1gfpm2f8shm9504y3fbdvzwjmqh5sn3pdzxs38p0kzil2h";
  };

  builder = ./rabbitmq_install_plugin.sh;

  meta = {
    homepage = https://github.com/rabbitmq/rabbitmq-delayed-message-exchange;
    description = "This plugin adds delayed-messaging (or scheduled-messaging) to RabbitMQ.";
  };
}
