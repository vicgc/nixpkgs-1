# Local PHP libs. These will be built for every configured PHP version.
{ pkgs, php, self, buildPecl }:

rec {

  mongodb = buildPecl {
    name = "mongodb-1.1.7";
    sha256 = "0jcvrxqpg8v5xn39hr2h49946nq5v5dhh1rgl117cfm5v5jbbgv5";

    configureFlags = [
      "--with-mongodb=${pkgs.mongodb}"
    ];

    buildInputs = [
       pkgs.pkgconfig
       pkgs.openssl
    ];
  };

  ssh2 = buildPecl {
    name = "ssh2-0.13";
    sha256 = "1gn1wqi3b4awmk0g701rrgj622lp9bm0dpx8v2y3cnqbhjmvhb6b";

    configureFlags = [
      "--with-ssh2=${pkgs.libssh2}"
    ];
  };

}
