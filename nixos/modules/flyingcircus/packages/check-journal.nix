{ pkgs, stdenv, fetchFromGitHub, rustPlatform }:

with rustPlatform;

buildRustPackage rec {
  name = "check-journal-${version}";
  version = "1.0.2";

  src = fetchFromGitHub {
    owner = "flyingcircusio";
    repo = "check_journal";
    rev = version;
    sha256 = "10qcsrwxv2kkza84girnz3jp7k537akfdgdrj3qv7xp76smklh6b";
  };

  cargoDepsSha256 = "1j1d0yc4qzg9m5bnsappiy9vds06hwnq1hnir4rc2221ggwpjlal";
  nativeBuildInputs = with pkgs; [ ronn ];
  OPENSSL_DIR = pkgs.openssl;

  postBuild = ''
    make
  '';
  postInstall = ''
    install -D check_journal.1 $out/share/man/man1/check_journal.1
  '';

  meta = with stdenv.lib; {
    description = "Nagios/Icinga compatible plugin to search `journalctl` output for matching lines.";
    homepage = https://github.com/flyingcircusio/check_journal;
    license = with licenses; [ bsd3 ];
    platforms = platforms.all;
  };
}
