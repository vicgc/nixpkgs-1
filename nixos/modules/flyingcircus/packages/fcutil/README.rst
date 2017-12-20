fc.util
=======

Contains generic utilities for the Flying Circus. Modules from this package are
generally required by other fc.* modules.


fc.util.directory
-----------------

Provide XML-RPC access to fc.directory. Usage example::

    directory = fc.util.directory.connect()


fc.util.spread
--------------

Library code which helps running management tasks only every N minutes. Meant to
provide reliable timing when called from a timer every M minutes, be M > N or
M < N.
