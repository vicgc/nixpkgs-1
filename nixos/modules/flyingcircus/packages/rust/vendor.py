#!/usr/bin/env python3

import argparse
import glob
import json
import os
import os.path as p
import re
import shutil

R_CRATENAME = re.compile(r'^(\S+?)-([0-9]\S+)\.crate$')

def scan_registry(rust_registry):
    for (dirpath, dirnames, filenames) in os.walk(rust_registry):
        for i, d in enumerate(dirnames):
            if d.startswith('.'):
                del dirnames[i]
        for f in filenames:
            if f.startswith('.'):
                continue
            yield f, p.join(dirpath, f)[len(rust_registry)+1:]


def pick(indexfile, version):
    with open(indexfile) as f:
        for line in f:
            idx = json.loads(line)
            if idx['vers'] == version:
                return line


def copy_indexfile(crate, rust_registry, lookup):
        m = R_CRATENAME.search(crate)
        if not m:
            raise RuntimeError('cannot parse crate file name', crate)
        shortname = m.group(1)
        version = m.group(2)
        index = lookup[shortname]
        target = p.join('index', index)
        os.makedirs(p.dirname(target), exist_ok=True)
        # append mode to allow for multiple versions of the same crate
        with open(target, 'a') as t:
            t.write(pick(p.join(rust_registry, index), version))



def main():
    argp = argparse.ArgumentParser(description="""\
Compiles a Rust registry subset to match a collection of local crates.
""")
    argp.add_argument('registry', metavar='RUST_REGISTRY',
                   help='path to a full local copy of the Rust registry')
    argp.add_argument('-d', '--dir', metavar='CRATEDIR', default='.',
                   help='directory containing *.crate files '
                   '(default: "%(default)s")')
    args = argp.parse_args()

    print('Scanning Rust registry...')
    lookup = {
        crate: idx
        for crate, idx in scan_registry(os.path.abspath(args.registry))
    }

    topdir = args.dir
    os.chdir(topdir)
    if p.isdir('index'):
        shutil.rmtree('index')
    elif p.islink('index'):
        os.unlink('index')

    print('Copying index files...')
    for crate in sorted(glob.glob("*.crate")):
        copy_indexfile(crate, args.registry, lookup)


if __name__ == '__main__':
    main()
