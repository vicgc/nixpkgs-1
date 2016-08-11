#!/bin/bash
# Generate a complete OpenVPN key setup using EasyRSA. This script is idempotent
# and should be called by
# system.activationScripts.openvpn-pki = "${generatePki}/generate-pki";
set -e
umask 022

DIR="@caDir@"
RG="@resource_group@"
LOCATION="@location@"
EASYRSA="@easyrsa@"
OPENVPN="@openvpn@"

ersa="$EASYRSA/bin/easyrsa --batch --days=999999"

if [[ ! -d $DIR ]]; then
    mkdir "$DIR"
    cd "$DIR"
    $EASYRSA/bin/easyrsa-init
fi

cd "$DIR"

if [[ ! -d pki ]]; then
    $ersa init-pki
fi

if [[ ! -f pki/ca.crt ]]; then
    $ersa --req-cn="OpenVPN CA/FCIO/$RG/$LOCATION" build-ca nopass
fi

gen_pair() {
    local cn="$1"
    local role="$2"
    crt="pki/issued/${cn}.crt"
    key="pki/private/${cn}.key"
    if [[ ! -f "$crt" || ! -f "$key" ]]; then
        $ersa build-${role}-full "$cn" nopass
        ln -fs "$crt" ${role}.crt
        ln -fs "$key" ${role}.key
    fi
}

gen_pair "vpn-${LOCATION}@${RG}.fcio.net" server
gen_pair "client-${LOCATION}@${RG}.fcio.net" client

if [[ ! -f pki/dh.pem ]]; then
    $ersa gen-dh
fi

if [[ ! -f ta.key ]]; then
    $OPENVPN/bin/openvpn --genkey --secret ta.key
fi
