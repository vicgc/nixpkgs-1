{ stdenv, fetchurl, perl
, enableACLs ? true, acl ? null
, enableCopyDevicesPatch ? false
}:

assert enableACLs -> acl != null;

stdenv.mkDerivation rec {
  name = "rsync-${version}";
  version = "3.1.3";

  mainSrc = fetchurl {
    # signed with key 0048 C8B0 26D4 C96F 0E58  9C2F 6C85 9FB1 4B96 A8C5
    url = "mirror://samba/rsync/src/rsync-${version}.tar.gz";
    sha256 = "1h0011dj6jgqpgribir4anljjv7bbrdcs8g91pbsmzf5zr75bk2m";
  };

  patchesSrc = fetchurl {
    # signed with key 0048 C8B0 26D4 C96F 0E58  9C2F 6C85 9FB1 4B96 A8C5
    url = "mirror://samba/rsync/rsync-patches-${version}.tar.gz";
    sha256 = "167vk463bb3xl9c4gsbxms111dk1ip7pq8y361xc0xfa427q9hhd";
  };

  srcs = [mainSrc] ++ stdenv.lib.optional enableCopyDevicesPatch patchesSrc;
  patches = stdenv.lib.optional enableCopyDevicesPatch "./patches/copy-devices.diff";

  buildInputs = stdenv.lib.optional enableACLs acl;
  nativeBuildInputs = [perl];

  configureFlags = "--with-nobody-group=nogroup";

  meta = with stdenv.lib; {
    homepage = http://rsync.samba.org/;
    description = "A fast incremental file transfer utility";
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
    maintainers = with maintainers; [ simons ehmry ];
  };
}
