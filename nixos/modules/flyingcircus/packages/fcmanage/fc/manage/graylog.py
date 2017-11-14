#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python34Packages.python -p python34Packages.requests2 -p python34Packages.click -I nixpkgs=/root/nixpkgs
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
import click
import json
import logging
import requests


logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.INFO)

log = logging.getLogger('fc-graylog')


@click.command()
@click.option('-u', '--user', default='admin', show_default=True)
@click.option('-p', '--password', default='admin', show_default=True)
@click.option('--input')
@click.option('--raw-path')
@click.option('--raw-data')
@click.argument('api')
def main(user, password, api, input, raw_path, raw_data):
    """Configure a Graylog input node."""
    graylog = requests.Session()
    graylog.auth = (user, password)

    if input:
        # check if there is input with this name currently configured,
        # if so return
        data = json.loads(input)
        log.info('Checking intput: %s', data['title'])
        response = graylog.get(api + '/system/cluster/node')
        response.raise_for_status()
        data['node'] = response.json()['node_id']
        response = graylog.get(api + '/system/inputs')
        response.raise_for_status()
        for _input in response.json()['inputs']:
            if _input['title'] == data['title']:
                log.info(
                    'Graylog input already configured. Updating: %s',
                    data['title'])
                response = graylog.put(
                    api + '/system/inputs/%s' % _input['id'], json=data)
                response.raise_for_status()
                break
        else:
            response = graylog.post(api + '/system/inputs', json=data)
            response.raise_for_status()
            log.info('Graylog input configured: %s', data['title'])

    if raw_path and raw_data:
        log.info('Update %s', raw_path)
        data = json.loads(raw_data)
        response = graylog.put(api + raw_path, json=data)
        response.raise_for_status()


if __name__ == '__main__':
    main()
