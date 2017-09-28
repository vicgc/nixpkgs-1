{ pkgs, stdenv, fetchFromGitHub, rustPlatform }:

with rustPlatform;

buildRustPackage rec {
  name = "fc-userscan-${version}";
  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "flyingcircusio";
    repo = "userscan";
    rev = version;
    sha256 = "08l83pcbxnqnq77wm2aj541nk2qqvpiw08ac2dmr1r6wz6v3qdb7";
  };

  cargoDepsSha256 = "0ddzxyn2ykmflxc4hw11vn7b7nk9l7bi83l4idx1m3qz0ywydcqc";
  nativeBuildInputs = with pkgs; [ git docutils ];
  propagatedBuildInputs = with pkgs; [ lzo ];
  doCheck = true;

  postBuild = ''
    substituteAll $src/userscan.1.rst $TMP/userscan.1.rst
    rst2man.py $TMP/userscan.1.rst > $TMP/userscan.1
  '';
  postInstall = ''
    install -D $TMP/userscan.1 $out/share/man/man1/fc-userscan.1
  '';

  meta = with stdenv.lib; {
    description = "Scan and register Nix store references from arbitrary files";
    homepage = https://github.com/flyingcircusio/userscan;
    license = with licenses; [ bsd3 ];
    platforms = platforms.all;
  };
}
