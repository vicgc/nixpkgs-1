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

    def __init__(self, dev, proj, mp):
        self.dev = dev    # block device
        self.proj = proj  # XFS project id (see /etc/projid)
        self.mp = mp      # mountpoint

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

    def should_grow_blkdev(self):
        """Returns True if a FS grow operation is necessary."""
        self.ensure_gpt_consistency()
        free = self.free_sectors()
        return free > self.FREE_SECTOR_THRESHOLD

    def grow(self):
        """Enlarges partition and filesystem."""
        free = self.free_sectors()
        print('{} free sectors on {}, growing'.format(free, self.dev))
        self.grow_partition()
        self.resize_partition()

    def xfsq(self, cmd, ionice=False):
        """Wrapper for xfs_quota calls."""
        cmd = ['xfs_quota', '-xc', cmd, self.mp]
        if ionice:
            cmd = ['ionice', '-c3'] + cmd
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL).\
            decode().strip()

    def xfs_quota_report(self):
        """Queries current XFS quota state.

        Example output:
            # xfs_quota -xc 'report -p' /
            Project quota on / (/dev/disk/by-label/root)
                                        Blocks
            Project ID       Used       Soft       Hard    Warn/Grace
            ---------- --------------------------------------------------
            rootfs       37208256   41943040   41943040     00 [--------]

        Returns pair of (used, block_hard_limit) numbers rounded to the
        next full GiB value.
        """
        report = self.xfsq('report -p')
        m = re.search(r'^{}\s+(\d+)\s+\d+\s+(\d+)\s+'.format(self.proj),
                      report, re.MULTILINE)
        if not m:
            raise RuntimeError('failed to parse xfs_quota output', report)
        used = m.group(1)
        blocks_hard = m.group(2)
        return (round(float(used) / 2**20), round(float(blocks_hard) / 2**20))

    def should_change_quota(self, partition, enc_disk_gb):
        """Returns True if a new quota setting is necessary."""
        if not enc_disk_gb:
            return False
        blk_size = subprocess.check_output(['lsblk', '-nbro', 'SIZE',
                                            partition]).decode().strip()
        blk_size_gb = int(round(float(blk_size) / 2**30))
        if enc_disk_gb > blk_size_gb:
            # disk grow pending
            return False
        used_gb, bhard_limit_gb = self.xfs_quota_report()
        print('resize: blk={} GiB, enc={} GiB, q_used={} GiB, q_limit={} GiB'
              .format(blk_size_gb, enc_disk_gb, used_gb, bhard_limit_gb))
        if enc_disk_gb == blk_size_gb and bhard_limit_gb == 0:
            # no action necessary; quota not active
            return False
        if enc_disk_gb < blk_size_gb and bhard_limit_gb != 0 and used_gb == 0:
            # something is fishy here -> reinit quota
            return True
        # logical disk size different from current quota? -> change quota
        return bhard_limit_gb != enc_disk_gb

    def set_quota(self, disk_gb):
        """Ensures only as much space as allotted can be used.

        XFS quotas are reinitialized no matter what since we don't know
        if we have been in a consistent state beforehand. This takes a
        bit longer than just setting bsoft and bhard values, but is also
        more reliable.
        """
        if not disk_gb:
            return
        print('resize: Setting XFS quota limits to {} GiB'.format(disk_gb))
        print(self.xfsq('project -s {}'.format(self.proj), ionice=True))
        print(self.xfsq('timer -p 1m' ))
        print(self.xfsq('limit -p bsoft={d}g bhard={d}g {p}'.format(
            d=disk_gb, p=self.proj)))

    def remove_quota(self):
        """Removes project quota as growing filesystems don't need it."""
        print('resize: Removing XFS quota')
        used, bhard_limit = self.xfs_quota_report()
        if used > 0:
            print(self.xfsq('project -C {}'.format(self.proj), ionice=True))
        if bhard_limit > 0:
            print(self.xfsq('limit -p bsoft=0 bhard=0 {}'.format(self.proj)))


def resize_filesystems(enc):
    """Grows root filesystem if the underlying blockdevice has been resized."""
    try:
        partition = subprocess.check_output(
            ['blkid', '-L', 'root']).decode().strip()
    except subprocess.CalledProcessError as e:
        if e.returncode == 2:
            # Label was not found.
            # This happends for instance on Vagrant, where it is no problem and
            # should not be an error.
            raise SystemExit(0)

    # The partition output is '/dev/vda1'. We assume we have a single-digit
    # partition number here.
    disk = partition[:-1]
    d = Disk(disk, 'rootfs', '/')
    enc_size = int(enc['parameters'].get('disk'))
    if d.should_grow_blkdev():
        d.remove_quota()
        d.grow()
    elif d.should_change_quota(partition, enc_size):
        d.set_quota(enc_size)


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

    if args.enc_path:
        with open(args.enc_path) as f:
            enc = json.load(f)
        resize_filesystems(enc)
        memory_change(enc)
        cpu_change(enc)


if __name__ == '__main__':
    main()
