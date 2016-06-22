{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.flyingcircus.roles;
  fclib = import ../lib;

  service = lib.findFirst
    (s: s.service == "nfs_rg_share-server")
    null
    config.flyingcircus.enc_services;

  export = "/srv/nfs/share";
  mount_point = "/mnt/nfs/share";

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
      fileSystems = {
        "/mnt/nfs/share" = {
          device = "${service.address}:${export}";
          fsType = "nfs";
          options = "intr,soft,bg,rsize=8192,wsize=8192";
        };
      };

      system.activationScripts.nfs_rg_client = ''
        install -d -g service -m 775 ${mount_point}
      '';
    })

    (mkIf cfg.nfs_rg_share.enable {
    })
  ];
}
