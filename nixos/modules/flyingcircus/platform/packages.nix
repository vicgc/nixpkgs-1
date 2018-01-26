{ config, pkgs, lib, ... }:

{
  config = {

    environment.systemPackages = with pkgs; [
        apacheHttpd
        atop
        automake
        bc
        bind
        bundler
        cmake
        curl
        cyrus_sasl
        db
        dstat
        fcbox
        fcmaintenance
        fcuserscan
        file
        fio
        gcc
        gdb
        gdbm
        git
        gnumake
        gnupg
        go
        gptfdisk
        graphviz
        htop
        imagemagick
        iotop
        jq
        kerberos
        libjpeg
        libmemcached
        libxml2
        libxslt
        links
        lsof
        lynx
        mercurial
        mmv
        nano
        nc6
        ncdu
        netcat
        ngrep
        nmap
        nodejs
        openldap
        openssl_1_0_2
        php
        pkgconfig
        protobuf
        psmisc
        pv
        pwgen
        python2Full
        python34
        pythonPackages.virtualenv
        ripgrep
        screen
        strace
        subversion
        sysstat
        tcpdump
        telnet
        traceroute
        tree
        unzip
        vim
        vulnix
        wget
        xfsprogs
        zlib
    ] ++
    lib.optional (!config.services.postgresql.enable) pkgs.postgresql;

    security.setuidPrograms = [ "box" ];
  };
}
