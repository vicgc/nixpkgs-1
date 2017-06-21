{ stdenv, rustPlatform, docutils }:

with rustPlatform;

buildRustPackage rec {
  name = "fc-box-${version}";
  version = "0.2.0";

  src = ./box;
  depsSha256 = "1bfm5zkiwm5ydq6n7ajp7vlsa6pgg0d1dyi9jsi4bakx6nf7nsyw";

  postBuild = ''
    substituteAllInPlace box.1.rst
    ${docutils}/bin/rst2man.py box.1.rst box.1
  '';

  postInstall = ''
    mkdir -p $out/share/man/man1
    mv box.1 $out/share/man/man1
  '';

  meta = with stdenv.lib; {
    description = "Manage Flying Circus NFS boxes";
    license = licenses.zpt21;
  };
}
