"""Scheduled machine reboot.

This activity does nothing if the machine has been booted for another reason in
the time between creation and execution.
"""

from fc.maintenance.activity import Activity
from fc.maintenance.reqmanager import ReqManager, DEFAULT_DIR
from fc.maintenance.request import Request

import argparse
import subprocess
import time


class RebootActivity(Activity):

    def __init__(self, action='reboot'):
        assert action in ['reboot', 'poweroff']
        self.action = action
        self.coldboot = (action == 'poweroff')
        # small allowance for VM clock skew
        self.initial_boottime = self.boottime() + 1

    @staticmethod
    def boottime():
        with open('/proc/uptime') as f:
            uptime = float(f.read().split()[0])
        return time.time() - uptime

    def boom(self):
        with open('starttime', 'w') as f:
            print(time.time(), file=f)
        subprocess.check_call(['systemctl', self.action])
        # We won't be able to pick up the return code of this command as
        # systemd terminates our process right away. The request will be
        # finished properly on the next fc.maintenance run. For the same
        # reason, updates for ourself won't be persisted by Request.save().

    def other_coldboot(self):
        """Returns True if there is also a cold reboot pending.

        Given that there are two reboot requests, one warm reboot and a
        cold reboot, the warm reboot will trigger and update boottime.
        Thus, the following cold reboot will not be performed (boottime
        > initial_boottime). But some setups require that the cold
        reboot must win regardless of issue order (e.g. Qemu), so we
        must skip warm reboots if a cold reboot is present.
        """
        try:
            for req in self.request.other_requests():
                if (isinstance(req.activity, RebootActivity) and
                        req.activity.coldboot):
                    self.returncode = 0
                    return True
        except AttributeError:
            return
        return False

    def run(self):
        if not self.coldboot and self.other_coldboot():
            self.returncode = 0
            return
        boottime = self.boottime()
        if not boottime > self.initial_boottime:
            self.boom()
            return
        self.stdout = 'booted at {} UTC'.format(
            time.asctime(time.gmtime(boottime)))
        self.returncode = 0
        try:
            with open('starttime') as f:
                started = float(f.read().strip())
                self.duration = time.time() - started
        except (IOError, ValueError):
            pass


def main():
    a = argparse.ArgumentParser(description=__doc__)
    a.add_argument('-c', '--comment', metavar='TEXT', default=None,
                   help='announce upcoming reboot with this message')
    a.add_argument('-p', '--poweroff', default=False, action='store_true',
                   help='power off instead of reboot')
    a.add_argument('-d', '--spooldir', metavar='DIR', default=DEFAULT_DIR,
                   help='request spool dir (default: %(default)s)')
    args = a.parse_args()

    action = 'poweroff' if args.poweroff else 'reboot'
    with ReqManager(spooldir=args.spooldir) as rm:
        rm.add(Request(RebootActivity(action),
                       900 if args.poweroff else 600,
                       args.comment if args.comment else 'Scheduled reboot'))
