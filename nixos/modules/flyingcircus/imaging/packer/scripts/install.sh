#!/bin/sh -e

REVISION=$1
export BRANCH=$2

packer_http=$(cat .packer_http)

# Partition disk
cat <<FDISK | fdisk /dev/sda
n




a
w

FDISK

# Create filesystem
mkfs.xfs -L nixos /dev/sda1

# Mount filesystem
mount LABEL=nixos /mnt

# Setup system
nixos-generate-config --root /mnt

echo Copying FCIO configuration
bash
cp /nix/var/nix/profiles/per-user/root/channels/nixos/nixos/modules/flyingcircus/files/etc_nixos_configuration.nix /mnt/etc/nixos/configuration.nix
cp /nix/var/nix/profiles/per-user/root/channels/nixos/nixos/modules/flyingcircus/files/etc_nixos_local.nix /mnt/etc/nixos/local.nix
curl -f "$packer_http/vagrant.nix" > /mnt/etc/nixos/vagrant.nix

echo Getting current code version
cd /mnt
nix-channel --update
nix-env -iA nixos.gitMinimal --option binary-caches "https://cache.nixos.org https://hydra.flyingcircus.io" --option trusted-binary-caches "*"
git clone https://github.com/flyingcircusio/nixpkgs
git checkout $REVISION

echo Starting nixos-install
### Install ###
nixos-install -I nixpkgs=/nixpkgs --option binary-caches "https://cache.nixos.org https://hydra.flyingcircus.io" --option trusted-binary-caches "*" --show-trace

rm -rf /mnt/nixpkgs

### Cleanup ###
curl "$packer_http/postinstall.sh" | nixos-install --chroot

