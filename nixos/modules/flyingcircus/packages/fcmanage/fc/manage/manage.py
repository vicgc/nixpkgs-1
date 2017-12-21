"""Update NixOS system configuration from infrastructure or local sources."""

from fc.util.directory import connect
from fc.util.lock import locked
from fc.util.spread import Spread
import argparse
import fc.maintenance
import fc.maintenance.lib.shellscript
import filecmp
import io
import json
import logging
import os
import os.path as p
import re
import requests
import shutil
import signal
import socket
import subprocess
import sys
import tempfile

# TODO
#
# - How do we cope for emergency updates where we need to update *now*? How can
#   we force this?

enc = {}
spread = None
logging.getLogger('requests').setLevel(logging.WARNING)

ACTIVATE = """\
set -e
nix-channel --add {url} nixos
nix-channel --update nixos
nixos-rebuild switch
nix-channel --remove next
"""

class Channel:

    PHRASES = re.compile('would (\w+) the following units: (.*)$')

    # global, to avoid re-connecting (with ssl handshake and all)
    session = requests.session()

    def __init__(self, url):
        self.url = self.resolved_url = url
        while True:
            response = self.session.head(self.resolved_url)
            response.raise_for_status()
            if response.is_redirect:
                self.resolved_url = response.headers['location']
            else:
                break
        self.resolved_url = self.resolved_url.rstrip('/')

    def __str__(self):
        def last(url):
            """Return last "significant" element from url."""
            for element in reversed(url.split('/')):
                if element:
                    return element
        channel = last(self.url)
        revision = last(self.resolved_url)
        if channel == revision:  # channel unknown
            return '<Channel {}>'.format(revision)
        else:
            return '<Channel {} ({})>'.format(
                revision, channel)

    def __eq__(self, other):
        if isinstance(other, Channel):
            return self.resolved_url == other.resolved_url
        return NotImplemented

    @classmethod
    def current(cls, channel_name):
        try:
            nix_channels = p.expanduser('~/.nix-channels')
            if p.getsize(nix_channels):
                with open(nix_channels) as f:
                    for line in f.readlines():
                        url, name = line.strip().split(' ', 1)
                        if name == channel_name:
                            return Channel(url)
        except OSError:
            return

    def load(self, name):
        """Load channel as given name."""
        subprocess.check_call(
            ['nix-channel', '--add', self.resolved_url, name])
        subprocess.check_call(['nix-channel', '--update', name])

    def switch(self, build_options):
        """Build the "self" channel and switch system to it."""
        logging.info('Building {}'.format(self))
        subprocess.check_call(
            ['nixos-rebuild', '--no-build-output', 'switch'] + build_options)

    def prepare_maintenance(self):
        logging.info('Preparing maintenance')
        self.load('next')
        call = subprocess.Popen(
             ['nixos-rebuild',
              '-I', 'nixpkgs=' + p.expanduser('~/.nix-defexpr/channels/next'),
              '--no-build-output',
              'dry-activate'],
             stderr=subprocess.PIPE)
        output = []
        for line in call.stderr.readlines():
            line = line.decode('UTF-8').strip()
            logging.warning(line)
            output.append(line)
        changes = self.detect_changes(output)
        self.register_maintenance(changes)

    def detect_changes(self, output):
        changes = {}
        for line in output:
            m = self.PHRASES.match(line)
            if m is not None:
                action = m.group(1)
                units = [unit.strip() for unit in m.group(2).split(',')]
                changes[action] = units
        return changes

    def register_maintenance(self, changes):
        def notify(category):
            services = changes.get(category, [])
            if services:
                return '{}: {}'.format(
                    category.capitalize(),
                    ', '.join(s.replace('.service', '', 1)
                              for s in services))
            else:
                return ''

        notifications = list(filter(None, (notify(cat)
                         for cat in ['stop', 'restart', 'start', 'reload'])))
        msg = ['System update to {}'.format(self)] + notifications
        if len(msg) > 1:  # add trailing newline if output is multi-line
            msg += ['']

        # XXX: We should use an fc-manage call (like --activate), instead of
        # Dumping the script into the maintenance request.
        script = io.StringIO(ACTIVATE.format(url=self.resolved_url))
        with fc.maintenance.ReqManager() as rm:
            rm.add(fc.maintenance.Request(
                fc.maintenance.lib.shellscript.ShellScriptActivity(script),
                300, comment='\n'.join(msg)))


class BuildState:
    """Track if fc-manage was last run from a channel or local checkout."""

    STATEDIR = "/var/lib/fc-manage"

    def __init__(self):
        self.dev_marker = p.join(self.STATEDIR, 'develop')

    def set_dev(self):
        if not p.exists(self.dev_marker):
            os.makedirs(self.STATEDIR, exist_ok=True)
            open(self.dev_marker, 'a').close()

    def set_channel(self):
        try:
            os.unlink(self.dev_marker)
        except OSError:
            pass

    @property
    def is_dev(self):
        return p.exists(self.dev_marker)


def load_enc(enc_path):
    """Tries to read enc.json"""
    global enc
    try:
        with open(enc_path) as f:
            enc = json.load(f)
    except (OSError, ValueError):
        # This environment doesn't seem to support an ENC,
        # i.e. Vagrant. Silently ignore for now.
        return


def conditional_update(filename, data):
    """Updates JSON file on disk only if there is different content."""
    with tempfile.NamedTemporaryFile(
            mode='w', suffix='.tmp', prefix=p.basename(filename),
            dir=p.dirname(filename), delete=False) as tf:
        json.dump(data, tf, ensure_ascii=False, indent=1, sort_keys=True)
        tf.write('\n')
        os.chmod(tf.fileno(), 0o640)
    if not(p.exists(filename)) or not(filecmp.cmp(filename, tf.name)):
        with open(tf.name, 'a') as f:
            os.fsync(f.fileno())
        os.rename(tf.name, filename)
    else:
        os.unlink(tf.name)


def inplace_update(filename, data):
    """Last-resort JSON update for added robustness.

    If there is no free disk space, `conditional_update` will fail
    because it is not able to create tempfiles. As an emergency measure,
    we fall back to rewriting the file in-place.
    """
    with open(filename, 'r+') as f:
        f.seek(0)
        json.dump(data, f, ensure_ascii=False)
        f.flush()
        f.truncate()
        os.fsync(f.fileno())


def write_json(calls):
    """Writes JSON files from a list of (lambda, filename) pairs."""
    for lookup, target in calls:
        logging.info('Retrieving {} ...'.format(target))
        try:
            data = lookup()
        except Exception:
            logging.exception('Error retrieving data:')
            continue
        try:
            conditional_update('/etc/nixos/{}'.format(target), data)
        except (IOError, OSError):
            inplace_update('/etc/nixos/{}'.format(target), data)


def system_state():
    def load_system_state():
        result = {}
        try:
            with open('/proc/meminfo') as f:
                for line in f:
                    if line.startswith('MemTotal:'):
                        _, memkb, _ = line.split()
                        result['memory'] = int(memkb) // 1024
                        break
        except IOError:
            pass
        try:
            with open('/proc/cpuinfo') as f:
                cores = 0
                for line in f:
                    if line.startswith('processor'):
                        cores += 1
            result['cores'] = cores
        except IOError:
            pass
        return result

    write_json([
        (lambda: load_system_state(), 'system_state.json'),
    ])


def update_inventory():
    if (not enc or not enc.get('parameters') or
            not enc['parameters'].get('directory_password')):
        logging.warning('No directory password. Not updating inventory.')
        return
    try:
        # For fc-manage all nodes need to talk about *their* environment which
        # is resource-group specific and requires us to always talk to the
        # ring 1 API.
        directory = connect(enc, 1)
    except socket.error:
        logging.warning('No directory connection. Not updating inventory.')
        return

    write_json([
        (lambda: directory.lookup_node(enc['name']), 'enc.json'),
        (lambda: directory.list_nodes_addresses(
            enc['parameters']['location'], 'srv'), 'addresses_srv.json'),
        (lambda: directory.list_permissions(), 'permissions.json'),
        (lambda: directory.list_service_clients(), 'service_clients.json'),
        (lambda: directory.list_services(), 'services.json'),
        (lambda: directory.list_users(), 'users.json'),
        (lambda: directory.lookup_resourcegroup('admins'), 'admins.json'),
    ])


def build_channel_with_maintenance(build_options):
    if not enc or not enc.get('parameters'):
        logging.warning('No ENC data. Not building channel.')
        return
    global spread
    if spread and not spread.is_due():
        return build(build_options)
    # always rebuild current channel (ENC updates, activation scripts etc.)
    current_channel = Channel.current('nixos')
    if current_channel:
        logging.info('Rebuilding {}'.format(current_channel))
        current_channel.switch(build_options)
    # scheduled update already present?
    if Channel.current('next'):
        rm = fc.maintenance.ReqManager()
        rm.scan()
        if rm.requests:
            logging.info('Channel update prebooked @ {}'.format(
                list(rm.requests.values())[0].next_due))
            return
    # scheduled update available?
    next_channel = Channel(enc['parameters'].get('environment_url'))
    if next_channel and next_channel != current_channel:
        logging.info('Preparing switch from {} to {}.'.format(
            current_channel, next_channel))
        next_channel.prepare_maintenance()


def build_channel(build_options):
    global spread
    if spread and not spread.is_due():
        return build(build_options)
    logging.info("Performing regular channel update.")
    try:
        if enc and enc.get('parameters'):
            channel = Channel(enc['parameters']['environment_url'])
        else:
            channel = Channel.current('nixos')
        if channel:
            channel.load('nixos')
            channel.switch(build_options)
            BuildState().set_channel()
    except Exception:
        logging.exception('Error switching channel')
        sys.exit(1)


def build_dev(build_options):
    logging.info("Building development checkout in /root/nixpkgs.")
    subprocess.check_call(
        ['nixos-rebuild', '-I', 'nixpkgs=/root/nixpkgs', 'switch'] +
        build_options)
    BuildState().set_dev()


def build(build_options):
    channel = Channel.current('nixos')
    if BuildState().is_dev or not channel:
        build_dev(build_options)
    else:
        try:
            channel.switch(build_options)
        except Exception:
            logging.exception('Error switching channel')
            sys.exit(1)


def maintenance():
    logging.info('Performing scheduled maintenance')
    import fc.maintenance.reqmanager
    fc.maintenance.reqmanager.transaction()


def seed_enc(path):
    if os.path.exists(path):
        return
    if not os.path.exists('/tmp/fc-data/enc.json'):
        return
    shutil.move('/tmp/fc-data/enc.json', path)


def exit_timeout(signum, frame):
    logging.error("Execution timed out. Exiting.")
    sys.exit(1)


def parse_args():
    a = argparse.ArgumentParser(description=__doc__)
    a.add_argument('-E', '--enc-path', default='/etc/nixos/enc.json',
                   help='path to enc.json (default: %(default)s)')
    a.add_argument('--show-trace', default=False, action='store_true',
                   help='instruct nixos-rebuild to dump tracebacks on failure')
    a.add_argument('--fast', default=False, action='store_true',
                   help='instruct nixos-rebuild to perform a fast rebuild')
    a.add_argument('-e', '--directory', default=False, action='store_true',
                   help='refresh local ENC copy')
    a.add_argument('-s', '--system-state', default=False, action='store_true',
                   help='dump local system information (like memory size) '
                   'to system_state.json')
    a.add_argument('-m', '--maintenance', default=False, action='store_true',
                   help='run scheduled maintenance')
    a.add_argument('-t', '--timeout', default=3600, type=int,
                   help='abort execution after <TIMEOUT> seconds')
    a.add_argument('-i', '--interval', default=120, type=int, metavar='INT',
                   help='automatic mode: channel update every <INT> minutes')
    a.add_argument('-f', '--stampfile', metavar='PATH',
                   default='/var/lib/fc-manage/fc-manage.stamp',
                   help='automatic mode: save last execution date to <PATH> '
                   '(default: (%(default)s)')
    a.add_argument('-a', '--automatic', default=False, action='store_true',
                   help='channel update every I minutes, local builds '
                   'all other times (see also -i and -f). Must be used in '
                   'conjunction with --channel or --channel-with-maintenance.')

    build = a.add_mutually_exclusive_group()
    build.add_argument('-c', '--channel', default=False, dest='build',
                       action='store_const', const='build_channel',
                       help='switch machine to FCIO channel')
    build.add_argument('-C', '--channel-with-maintenance', default=False,
                       dest='build', action='store_const',
                       const='build_channel_with_maintenance',
                       help='switch machine to FCIO channel during scheduled '
                       'maintenance')
    build.add_argument('-d', '--development', default=False, dest='build',
                       action='store_const', const='build_dev',
                       help='switch machine to local checkout in '
                       '/root/nixpkgs')
    build.add_argument('-b', '--build', default=False, dest='build',
                       action='store_const', const='build',
                       help='rebuild channel or local checkout whatever '
                       'is currently active')
    a.add_argument('-v', '--verbose', action='store_true', default=False)

    args = a.parse_args()
    return args


def transaction(args):
    seed_enc(args.enc_path)

    build_options = []
    if args.show_trace:
        build_options.append('--show-trace')
    if args.fast:
        build_options.append('--fast')

    if args.directory:
        load_enc(args.enc_path)
        update_inventory()

    if args.system_state:
        system_state()

    # reload ENC data in case update_inventory changed something
    load_enc(args.enc_path)

    if args.automatic:
        global spread
        spread = Spread(args.stampfile, args.interval * 60, 'Channel update')
        spread.configure()

    if args.build:
        globals()[args.build](build_options)

    if args.maintenance:
        maintenance()


def main():
    args = parse_args()
    signal.signal(signal.SIGALRM, exit_timeout)
    signal.alarm(args.timeout)

    logging.basicConfig(format='%(levelname)s: %(message)s',
                        level=logging.DEBUG if args.verbose else logging.INFO)
    # this is really annoying
    logging.getLogger('iso8601').setLevel(logging.INFO)

    lockprefix = p.expanduser('~/.') if os.geteuid() else '/run/lock'
    with locked(lockprefix + 'fc-manage.lock'):
        transaction(args)


if __name__ == '__main__':
    main()
