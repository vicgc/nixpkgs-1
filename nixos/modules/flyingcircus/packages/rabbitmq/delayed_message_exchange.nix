{ pkgs ? import <nixpkgs> { }
, stdenv ? pkgs.stdenv
, lib ? pkgs.lib
, fetchurl ? pkgs.fetchurl
}:


stdenv.mkDerivation rec {
  name = "rabbitmq_delayed_message_exchange-${version}";
  version = "0.0.1";

  src = fetchurl {
    url = "http://www.rabbitmq.com/community-plugins/v3.6.x/rabbitmq_delayed_message_exchange-0.0.1.ez";
    sha256 = "1v46lfidwqzmw37ymipc83r6z4cdjqs0mxgad2bbl3vkj655sjf2";
  };

  builder = ./install_plugin.sh;

  meta = {
    homepage = https://github.com/rabbitmq/rabbitmq-delayed-message-exchange;
    description = "This plugin adds delayed-messaging (or scheduled-messaging) to RabbitMQ.";
  };
}
