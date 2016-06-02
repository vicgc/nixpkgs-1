{ ... }:

{

  nixpkgs.config.packageOverrides = pkgs: rec {

    innotop = pkgs.callPackage ./innotop.nix { };
    percona = pkgs.callPackage ./percona.nix { boost = (pkgs.callPackage ../boost-1.59.nix {}); };
    qpress = pkgs.callPackage ./qpress.nix { };
    xtrabackup = pkgs.callPackage ./xtrabackup.nix { };


  };

}
