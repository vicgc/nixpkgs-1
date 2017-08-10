{ stdenv, rustPlatform, docutils }:

with rustPlatform;

buildRustPackage rec {
  name = "fc-box-${version}";
  version = "0.2.0";

  src = ./box;
  cargoDepsSha256 = "1nla3bp3yifkhjww7rp65i9xlv91scrsg7y8szy18sngn0ji20ac";
  doCheck = true;

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
