{ config, lib, pkgs, ... }:

with lib;

{
  imports = [
      <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
      <nixpkgs/nixos/modules/profiles/clone-config.nix>
  ];

  # Images are provisioned independent of their data center location.
  flyingcircus.enc.parameters.location = "standalone";

  # Enable DHCP on SRV for bootstrapping, bypassing the regular ENC logic.
  networking.interfaces.ethsrv.useDHCP = true;

  # Providing the expected device-indepentend symlink wasn't easily possible,
  # so we just start with the fixed known environment here.
  boot.loader.grub.device = mkOverride 10 "/dev/vda";

  system.build.flyingcircusVMImage =
    pkgs.vmTools.runInLinuxVM (
      pkgs.runCommand "flyingcircus-image"
        rec {
          preVM = ''
            export PATH=${makeBinPath buildInputs}:$PATH
            mkdir $out
            diskImage=$out/image.qcow2
            ${pkgs.vmTools.qemu}/bin/qemu-img create -f qcow2 -o preallocation=metadata,compat=1.1,lazy_refcounts=on $diskImage "10G"
            mv closure xchg/

            # Copy all paths in the closure to the filesystem.
            # We package them up to speed up the whole process instead of
            # doing it file-by-file.
            echo "taring store paths"
            storePaths=$(perl ${pkgs.pathsFromGraph} xchg/closure)
            tar c $storePaths | lz4 --no-frame-crc > xchg/store.tar.lz4
          '';
          postVM = ''
            export PATH=${makeBinPath buildInputs}:$PATH
            echo "compressing VM image"
            lz4 $diskImage ''${diskImage}.lz4
            rm $diskImage
          '';
          memSize = 2048;
          QEMU_OPTS = "-smp 8";
          buildInputs = with pkgs; [
            utillinux perl lz4 gnutar xfsprogs gptfdisk
          ];
          exportReferencesGraph =
            [ "closure" config.system.build.toplevel ];
        }
        ''
          # Create a root and bootloader partitions
          sgdisk /dev/vda -o
          sgdisk /dev/vda -a 8192 -n 1:8192:0 -c 1:root -t 1:8300
          sgdisk /dev/vda -n 2:2048:+1M -c 2:gptbios -t 2:EF02
          . /sys/class/block/vda1/uevent
          mknod /dev/vda1 b $MAJOR $MINOR

          # Create an empty filesystem and mount it.
          mkfs.xfs -m crc=1,finobt=1 -L root /dev/vda1
          mkdir /mnt
          mount /dev/vda1 /mnt

          # The initrd expects these directories to exist.
          mkdir /mnt/dev /mnt/proc /mnt/sys
          mount --bind /proc /mnt/proc
          mount --bind /dev /mnt/dev
          mount --bind /sys /mnt/sys

          echo "untaring store paths"
          lz4 -d --no-frame-crc /tmp/xchg/store.tar.lz4 | tar x -C /mnt

          # Register the paths in the Nix database.
          printRegistration=1 perl ${pkgs.pathsFromGraph} /tmp/xchg/closure | \
              chroot /mnt ${config.nix.package}/bin/nix-store --load-db --option build-users-group ""

          # Create the system profile to allow nixos-rebuild to work.
          chroot /mnt ${config.nix.package}/bin/nix-env --option build-users-group "" \
              -p /nix/var/nix/profiles/system --set ${config.system.build.toplevel}

          # `nixos-rebuild' requires an /etc/NIXOS.
          mkdir -p /mnt/etc
          touch /mnt/etc/NIXOS

          # `switch-to-configuration' requires a /bin/sh
          mkdir -p /mnt/bin
          ln -s ${config.system.build.binsh}/bin/sh /mnt/bin/sh

          # Install our local, unmanaged configuration template.
          mkdir -p /mnt/etc/nixos
          cp ${../files/etc_nixos_local.nix} /mnt/etc/nixos/local.nix
          chmod u+rw /mnt/etc/nixos/local.nix

          # Generate the GRUB menu.
          chroot /mnt ${config.system.build.toplevel}/bin/switch-to-configuration boot

          umount /mnt/proc /mnt/dev /mnt/sys
          umount /mnt
        ''
    );

}
