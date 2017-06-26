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
        imagemagick
        iotop
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
        python2Full
        python34
        pythonPackages.virtualenv
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
