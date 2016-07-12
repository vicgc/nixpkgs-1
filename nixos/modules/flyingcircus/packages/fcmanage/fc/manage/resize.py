"""Resizes filesystems or memory if needed.

We expect the root partition to be partition 1 on its device, but we're
looking up the device by checking the root partition by label first.
"""

import argparse
import fc.manage.dmi_memory
import fc.maintenance
import fc.maintenance.lib.reboot
import json
import re
import subprocess


class Disk(object):
    """Resizes root filesystem.

    This part of the resizing code does not know or care about the
    intended size of the disk. It only checks what size the disk has and
    then aligns the partition table and filesystems appropriately.

    The actual sizing of the disk is delegated to the KVM host
    management utilities and happens independently.

    Some of the tools need partition numbers, though. We hardcoded that
    for now.
    """

    # 5G disk size granularity -> 2.5G sampling -> 512 byte sectors
    FREE_SECTOR_THRESHOLD = (5 * (1024 * 1024 * 1024) / 2) / 512

    def __init__(self, dev):
        self.dev = dev

    def ensure_gpt_consistency(self):
        sgdisk_out = subprocess.check_output([
            'sgdisk', '-v', self.dev]).decode()
        if 'Problem: The secondary' in sgdisk_out:
            print('resize: Ensuring GPT consistency')
            print(sgdisk_out)
            subprocess.check_call(['sgdisk', '-e', self.dev])

    r_free = re.compile(r'\s([0-9]+) free sectors')

    def free_sectors(self):
        sgdisk_out = subprocess.check_output([
            'sgdisk', '-v', self.dev]).decode()
        free = self.r_free.search(sgdisk_out)
        if not free:
            raise RuntimeError('unable to determine number of free sectors',
                               sgdisk_out)
        return(int(free.group(1)))

    def grow_partition(self):
        print('resize: Growing partition in the partition table')
        partx = subprocess.check_output(['partx', '-r', self.dev]).decode()
        first_sector = partx.splitlines()[1].split()[1]
        subprocess.check_call([
            'sgdisk', self.dev, '-d', '1',
            '-n', '1:{}:0'.format(first_sector), '-c', '1:root',
            '-t', '1:8300'])

    def resize_partition(self):
        print('resize: Growing XFS filesystem')
        partx = subprocess.check_output(['partx', '-r', self.dev]).decode()
        partition_size = partx.splitlines()[1].split()[3]   # sectors
        subprocess.check_call(['resizepart', self.dev, '1', partition_size])
        subprocess.check_call(['xfs_growfs', '/dev/disk/by-label/root'])

    def grow(self):
        self.ensure_gpt_consistency()
        free = self.free_sectors()
        if free > self.FREE_SECTOR_THRESHOLD:
            print('{} free sectors on {}, growing'.format(free, self.dev))
            self.grow_partition()
            self.resize_partition()


def resize_filesystems():
    """Grows root filesystem if the underlying blockdevice has been resized."""
    try:
        partition = subprocess.check_output(['blkid', '-L', 'root']).decode()
    except subprocess.CalledProcessError as e:
        if e.returncode == 2:
            # Label was not found.
            # This happends for instance on Vagrant, where it is no problem and
            # should not be an error.
            raise SystemExit(0)

    # The partition output is '/dev/vda1'. We assume we have a single-digit
    # partition number here.
    disk = partition.strip()[:-1]
    d = Disk(disk)
    d.grow()


def set_quota(enc):
    """Ensures only as much space as allotted can be used."""
    disksize = int(enc['parameters'].get('disk', 0))  # GiB
    if not disksize:
        return
    print('resize: Setting XFS quota to {} GiB'.format(disksize))
    subprocess.check_call([
        'xfs_quota', '-xc',
        'limit -p bsoft={d}g bhard={d}g root'.format(d=disksize), '/'])


def count_cores(cpuinfo='/proc/cpuinfo'):
    count = 0
    with open(cpuinfo) as f:
        for line in f.readlines():
            if line.startswith('processor'):
                count += 1
    assert count > 0
    return count


def memory_change(enc):
    """Schedules reboot if the memory size has changed."""
    enc_memory = int(enc['parameters'].get('memory', 0))
    if not enc_memory:
        return
    real_memory = fc.manage.dmi_memory.main()
    if real_memory == enc_memory:
        return
    msg = 'Reboot to change memory from {} MiB to {} MiB'.format(
        real_memory, enc_memory)
    print('resize:', msg)
    with fc.maintenance.ReqManager() as rm:
        rm.add(fc.maintenance.Request(
            fc.maintenance.lib.reboot.RebootActivity('poweroff'), 900, msg))


def cpu_change(enc):
    """Schedules reboot if the number of cores has changed."""
    cores = int(enc['parameters'].get('cores', 0))
    if not cores:
        return
    current_cores = count_cores()
    if current_cores == cores:
        return
    msg = 'Reboot to change CPU count from {} to {}'.format(
        current_cores, cores)
    print('resize:', msg)
    with fc.maintenance.ReqManager() as rm:
        rm.add(fc.maintenance.Request(
            fc.maintenance.lib.reboot.RebootActivity('poweroff'), 900, msg))


def main():
    a = argparse.ArgumentParser(description=__doc__)
    a.add_argument('-E', '--enc-path', default='/etc/nixos/enc.json',
                   help='path to enc.json (default: %(default)s)')
    args = a.parse_args()

    resize_filesystems()

    if args.enc_path:
        with open(args.enc_path) as f:
            enc = json.load(f)
        set_quota(enc)
        memory_change(enc)
        cpu_change(enc)


if __name__ == '__main__':
    main()
