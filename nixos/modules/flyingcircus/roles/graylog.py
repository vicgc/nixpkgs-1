#! /run/current-system/sw/bin/env nix-shell
#! nix-shell -i python3 -p python35Packages.python -p python35Packages.requests2 -p python35Packages.click -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/master.tar.gz
#
# input sample
# {
#     "configuration":  {
#     "tls_key_password":  "P@ssw0rd",
#     "recv_buffer_size":  1048576,
#     "max_message_size":  2097152,
#     "bind_address":  "0.0.0.0",
#     "port":  12201,
#     "tls_enable":  false,
#     "use_null_delimiter":  true
#     },
#     "title":  "myNewGlobalGelfTcpInput",
#     "global":  true,
#     "type":  "org.graylog2.inputs.gelf.tcp.GELFTCPInput"
# }
# 201 -> success
# returns input id
#
# requests.post(api + '/system/inputs/', auth=(user, pw), json=data).text
# >>> '{"id":"57fe09c2ec3fa136a780adb9"}'

import requests
import sys
import json
import click


@click.command
@click.option('-u', '--user', default='admin)
@click.option('-p', '--password', default='admin')
@click.option('-a', '--api')
@click.argument('data',
                help='graylog input definition as json string')
def cli(user, password, api, data):
    # get node_id
    r = requests.get(api + '/system/cluster/node', auth=(user, pw))
    r.raise_for_status()
    node_id = r.json()['node_id']

    # check if there is input on this _port_ currently _running_
    r = requests.get(api + '/system/inputstates', auth=(user, pw))
    r.raise_for_status()
    for _input in r.json()['states']:
        if _input['name'] == data['title']:
            print(_input)
            sys.exit(1)

    # create input for UDP
    r = requests.post(api + '/system/inputs', auth=(user, pw), json=data)
    r.raise_for_status()
    input_id = r.json()['input_id']

    # get all configured inputs
    r = requests.get(api + '/system/inputs', auth=(user, pw))

if __name__ == '__main__':
    cli()
