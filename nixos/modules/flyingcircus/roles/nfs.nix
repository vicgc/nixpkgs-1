# NFS resource group share.
# Note that activating both nfs_rg_share and nfs_rg_client currently fails due
# to a race condition. Re-run fc-manage in this case.
# RG shares exported from a NixOS server cannot be written to by service users
# running Gentoo and vice versa.
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.flyingcircus;
  fclib = import ../lib;

  service = findFirst
    (s: s.service == "nfs_rg_share-server")
    {}
    cfg.enc_services;

  export = "/srv/nfs/shared";
  mountpoint = "/mnt/nfs";
  mountopts = "rw,soft,intr,rsize=8192,wsize=8192,noauto,x-systemd.automount";

  service_clients = filter
    (s: s.service == "nfs_rg_share-server")
    cfg.enc_service_clients;

  # This is a bit different than on Gentoo. We allow export to all nodes in the
  # RG, regardles of the node actually being a client.
  export_to_clients =
    let
      flags = "rw,sync,root_squash,no_subtree_check";
      clientWithFlags = c: "${c.node}(${flags})";
    in
      concatMapStringsSep " " clientWithFlags service_clients;

  boxServer = findFirst (s: s.service == "box-server") {} cfg.enc_services;
  boxMount = "/mnt/auto/box";

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
    (mkIf (cfg.roles.nfs_rg_client.enable && service ? address) {
      fileSystems = {
        "${mountpoint}/shared" = {
          device = "${service.address}:${export}";
          fsType = "nfs4";
          options = mountopts;
        };
      };
      systemd.tmpfiles.rules = [
        "d ${mountpoint}"
      ];
      services.logrotate.config = ''
        /var/log/autofs {
        }
      '';
    })

    (mkIf (cfg.roles.nfs_rg_share.enable && service_clients != []) {
      services.nfs.server.enable = true;
      services.nfs.server.exports = ''
        ${export}  ${export_to_clients}
      '';
      system.activationScripts.nfs_rg_share = ''
        install -d -g service -m 775 ${export}
        ${pkgs.nfs-utils}/bin/exportfs -ra
      '';
    })

    (mkIf (boxServer ? address) (
      let
        humanUsers =
          (filterAttrs (n: v: v.isNormalUser && v.group == "users")
          config.users.users);
      in
      {
        fileSystems = (listToAttrs
          (map
            (user: nameValuePair
              "${boxMount}/${user}"
              {
                device = "${boxServer.address}:/srv/nfs/box/${user}";
                fsType = "nfs4";
                options = mountopts;
              })
            (attrNames humanUsers)));
        systemd.tmpfiles.rules =
          [ "d ${boxMount}" ] ++
          mapAttrsToList
            (user: v: "L ${v.home}/box - - - - ${boxMount}/${user}")
            humanUsers;
      }))
  ];
}
