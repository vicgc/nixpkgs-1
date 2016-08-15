""" Journal check.

Takes a set of regular expression, tries to match them with the output of
journalctl and if positive prints them.
"""

import argparse
import json
import logging
import nagiosplugin
import re
import subprocess
import yaml

from functools import reduce

_log = logging.getLogger('nagiosplugin')


class Journal(nagiosplugin.Resource):

    def __init__(self, params, src):
        self.params = params
        self.journalctl = self.params.journalctl
        self.src = src

        self.warnings = []
        self.criticals = []

    def find_hits(self):
        critical_hits = []
        warning_hits = []
        try:
            log = subprocess.check_output(self.journalctl,
                                          stderr=subprocess.STDOUT,
                                          shell=True).\
                decode().strip().split('\n')
        except subprocess.CalledProcessError as e:
            ret = e.returncode
            # journalctl returns 256, if the the filtered output is empty
            # we may exit the whole process
            if ret == 256:
                return([], [])
            # systemd < 223 returns stupid output in case of zero entries
            # zero entries == ok
            elif ret == 1 and 'timestamp' in e.output.decode():
                return([], [])
            else:
                raise
        # convert the list of json objects to a list of python objects
        log = [json.loads(entry) for entry in log]

        _log.debug('complete log:\n')
        for entry in log:
            _log.debug(entry['MESSAGE'])
        with open(self.src) as fobj:
            patterns = yaml.safe_load(fobj)
        _log.debug('patterns:\n%r', patterns)

        # create a list of match candidates by applying the rules
        # xxx: unfortunately entry['MESSAGE'] contains not only strings
        # all the time, needs further testing
        warning_hits = [
            entry['MESSAGE']
            for rule in patterns['warningpatterns']
            for entry in log
            if re.search(rule, str(entry['MESSAGE']))
        ]
        _log.info('warning hits (w/o exceptions):\n%s',
                  '\n'.join(warning_hits))

        # reducing them by exceptions of the rule

        # Info: We need to carry the list of warning hits by applying the
        # exception rules individually on the shrinking list!

        if warning_hits and 'warningexceptions' in patterns:
            warning_hits = \
                reduce(lambda H, e:
                       [h for h in H if not re.search(e, h)],
                       patterns['warningexceptions'],
                       warning_hits)

        # do that for critical as well
        critical_hits = [
            entry['MESSAGE']
            for rule in patterns['criticalpatterns']
            for entry in log
            if re.search(rule, str(entry['MESSAGE']))
        ]
        _log.info('critical hits (w/o exceptions):\n%s',
                  '\n'.join(critical_hits))

        # reducing them by exceptions of the rule

        if critical_hits and 'criticalexceptions' in patterns:
            warning_hits = \
                reduce(lambda H, e:
                       [h for h in H if not re.search(e, h)],
                       patterns['criticalexceptions'],
                       warning_hits)

        return (warning_hits, critical_hits)

    def probe(self):
        self.warnings, self.criticals = self.find_hits()

        return [nagiosplugin.Metric('warning', len(self.warnings), min=0),
                nagiosplugin.Metric('critical', len(self.criticals), min=0)]


class JournalSummary(nagiosplugin.Summary):

    def ok(self, results):
        return 'no errors found'

    def problem(self, results):
        return '{} {} line(s) found\n'.format(
            results.most_significant[0].metric.value,
            results.most_significant_state)

    def verbose(self, results):
        res = ''
        if results['critical'].metric.value:
            res += ('critical hits:\n' +
                    '\n'.join(results['critical'].resource.criticals) + '\n')
        if results['warning'].metric.value:
            res += ('warning hits:\n' +
                    '\n'.join(results['warning'].resource.warnings) + '\n')
        return res


@nagiosplugin.guarded
def main():
    a = argparse.ArgumentParser()
    a.add_argument('-j', '--journalctl', dest='journalctl',
                   default='journalctl --no-pager -o json ' +
                   '--since=-10minutes',
                   help='journalctl invocation (default: %(default)s)')
    a.add_argument('config')
    a.add_argument('-t', '--timeout', default=10,
                   help='about execution after TIMEOUT seconds')
    a.add_argument('-v', '--verbose', action='count', default=0)

    args = a.parse_args()
    check = nagiosplugin.Check(
        Journal(params=args, src=args.config),
        nagiosplugin.ScalarContext('warning', warning="0:0"),
        nagiosplugin.ScalarContext('critical', critical="0:0"),
        JournalSummary())
    check.main(args.verbose, args.timeout)

if __name__ == '__main__':
    main()
