# NFS resource group share.
# Note that activating both nfs_rg_share and nfs_rg_client currently fails due
# to a race condition. Re-run fc-manage in this case.
# RG shares exported from a NixOS server cannot be written to by service users
# running Gentoo and vice versa.
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.flyingcircus.roles;
  fclib = import ../lib;

  service = lib.findFirst
    (s: s.service == "nfs_rg_share-server")
    {}
    config.flyingcircus.enc_services;

  export = "/srv/nfs/shared";
  mount_point = "/mnt/nfs/shared";

  service_clients = filter
    (s: s.service == "nfs_rg_share-server")
    config.flyingcircus.enc_service_clients;

  # This is a bit different than on Gentoo. We allow export to all nodes in the
  # RG, regardles of the node actually being a client.
  export_to_clients =
    let
      flags = "rw,sync,root_squash,no_subtree_check";
    in
      lib.concatStringsSep " "
        (map
          (s: "${s.node}(${flags})")
          service_clients);

in
{
  options = {

    flyingcircus.roles.nfs_rg_client = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable the Flying Circus nfs client role.

          This mounts /srv/nfs/shared from the server to /mnt/nfs/shared.
        '';
      };
    };

    flyingcircus.roles.nfs_rg_share = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable the Flying Circus nfs server role.

          This exports /srv/nfs/shared.
        '';
      };

    };
  };

  config = mkMerge [
    (mkIf cfg.nfs_rg_client.enable {
      # mount service.address
      fileSystems = assert service != {}; {
        "${mount_point}" = {
          device = "${service.address}:${export}";
          fsType = "nfs4";
          options = "intr,soft,bg,rsize=8192,wsize=8192";
        };
      };

      system.activationScripts.nfs_rg_client = ''
        install -d -g service -m 775 ${mount_point}
      '';
    })

    (mkIf cfg.nfs_rg_share.enable {
      services.nfs.server.enable = true;
      services.nfs.server.exports = ''
        ${export}  ${export_to_clients}
      '';
      system.activationScripts.nfs_rg_share = ''
        install -d -g service -m 775 ${export}
      '';
    })
  ];
}
