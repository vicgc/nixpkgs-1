fc.manage
=========

fc.manage is our wrapper around nixos-rebuild. It is intended to be run both
from a systemd timer and manually from a root shell.

fc.manage does not only run nixos-rebuild, but performs additional regular
maintenance tasks so this is a one-stop solution for FC VMs.

fc-manage usage
---------------

The main modes of operation are as follows:

fc-manage --channel
    Download the latest FC nixpkgs from our hydra and update the system. This is
    what the systemd timer usually does.

fc-manage --development
    Updates the system against a local nixpkgs checkout in `/root/nixpkgs`. The
    latter can also be a symlink to a checkout residing in a user's home
    directory.

fc-manage --directory
    Updates various ENC dumps in `/etc/nixos` from the directory.


Invoke `fc-manage --help` for a full list of options.


Flying Circus integration
-------------------------

The most important NixOS options in `/etc/nixos/local.nix` that control the
fc.manage timers are:

flyingcircus.agent.enable
    Set to false to disable the timer (default: true). Note that you must run
    fc-manage at least once manually after resetting this options, else the
    change will not be picked up.

flyingcircus.agent.steps
    Controls the configuration steps which are run each time the timer triggers.


fc-resize usage
---------------

fc-resize checks the root volume size, the memory size and the number of virtual
cores against what ENC data say. The root volume can be transparently increased,
but for changing RAM size or the number of cores a reboot is scheduled.

It should hardly be necessary to call fc-resize from an interactive session.


Hacking
-------

Create a virtualenv::

    pyvenv-3.4 .
    bin/pip install -e ../fcutil
    bin/pip install -e ../fcmaintenance
    bin/pip install -e .\[test]

Run tests::

    bin/py.test
