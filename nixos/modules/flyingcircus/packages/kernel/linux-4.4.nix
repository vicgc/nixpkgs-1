{ stdenv, fetchurl, perl, buildLinux, lib, ... } @ args:

let
  kernel = import ../../../../../pkgs/os-specific/linux/kernel/generic.nix
    (args // rec {
      version = "4.4.91";
      extraMeta.branch = "4.4";

      src = fetchurl {
        url = "mirror://kernel/linux/kernel/v4.x/linux-${version}.tar.xz";
        sha256 = "1ysg4ly5qp65hc79s8pwh1yg7xf9ki16azdwwm6l2n7y3a62p7fb";
      };

      kernelPatches = args.kernelPatches;
      extraConfig = ''
        IP_MULTIPLE_TABLES y
        IPV6_MULTIPLE_TABLES y
        LATENCYTOP y
        SCHEDSTATS y
      '';

      features.iwlwifi = false;
      features.efiBootStub = true;
      features.needsCifsUtils = true;
      features.canDisableNetfilterConntrackHelpers = true;
      features.netfilterRPFilter = true;
    } // (args.argsOverride or {}));

in
lib.overrideDerivation
  kernel
  (old: {
    # Postprocessing: disable very time and space consuming subsystems which
    # cannot be altered by NixOS' own configuration mechanism
    postConfigure = ''
      sed -i \
        -e "s/^CONFIG_BTRFS_FS=.*/# CONFIG_BTRFS_FS is not set/" \
        -e "s/^CONFIG_DRM=.*/# CONFIG_DRM is not set/" \
        -e "s/^CONFIG_SOUND=.*/# CONFIG_SOUND is not set/" \
        -e "s/^CONFIG_STAGING=.*/# CONFIG_STAGING is not set/" \
        -e "s/^CONFIG_WLAN=.*/# CONFIG_WLAN is not set/" \
        $buildRoot/.config
      make $makeFlags "''${makeFlagsArray[@]}" oldconfig
    '';
  })
