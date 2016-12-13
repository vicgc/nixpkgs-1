{ pkgs }:

pkgs.callPackage ../../../../pkgs/tools/system/collectd {
  libsigrok = null;
  libvirt = null;
  lm_sensors = null;  # probably not seen on VMs
  lvm2 = null;        # dito
}
