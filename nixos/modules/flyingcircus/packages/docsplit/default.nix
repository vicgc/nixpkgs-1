{ lib, bundlerApp, ruby, pkgs, stdenv, ...}:
bundlerApp {
  pname = "docsplit";
  ruby = ruby;
  gemdir = ./.;
  exes = [ "docsplit" ];

  meta = with lib; {
    description = "A command-line utility and Ruby library for splitting apart documents into their component parts";
    homepage    = https://documentcloud.github.io/docsplit/;
    license     = licenses.lgpl2;
    maintainers = with maintainers; [ zagy ];
    platforms   = platforms.unix;
  };

}
