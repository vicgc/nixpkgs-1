""" Journal check.

Takes a set of regular expression, tries to match them with the output of
journalctl and if positive prints them.
"""

import argparse
import logging
import nagiosplugin
import re
import subprocess
import yaml

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
        log = subprocess.check_output(self.journalctl, shell=True).decode().splitlines()
        with open(self.src) as fobj:
                    patterns = yaml.load(fobj)

        # create a list of match candidates by applying the rules
        warning_hits = [
            entry
            for rule in patterns['warningpatterns']
            for entry in log
            if re.search(rule, entry)
        ]
        # reducing them by exceptions of the rule
        if warning_hits: warning_hits = [
            entry
            for rule in patterns['warningexceptions']
            for entry in warning_hits
            if not re.search(rule, entry)
        ]

        # do that for critical as well
        critical_hits = [
            entry
            for rule in patterns['criticalpatterns']
            for entry in log
            if re.search(rule, entry)
        ]
        # reducing them by exceptions of the rule
        if critical_hits: critical_hits = [
            entry
            for rule in patterns['criticalexceptions']
            for entry in critical_hits
            if not re.search(rule, entry)
        ]

        return (warning_hits, critical_hits)


    def probe(self):

        self.warnings, self.criticals = self.find_hits()

        metric_warning = 0
        if self.warnings:
            metric_warning = 1

        metric_critical = 0
        if self.criticals:
            metric_critical = 2

        return [nagiosplugin.Metric('warning', metric_warning, min=0),
                nagiosplugin.Metric('critical', metric_critical, min=0)]

class JournalSummary(nagiosplugin.Summary):

    def verbose(self, results):
        if 'warning' in results:
            return 'journal: ' + '\n'.join(results['warning'].resource.warnings)
        if 'critical' in results:
            return 'journal: ' + '\n'.join(results['critical'].resource.criticals)


@nagiosplugin.guarded
def main():
    a = argparse.ArgumentParser()
    a.add_argument('-j', '--journalctl', dest='journalctl',
                   default='journalctl --no-pager -a --since=-10minutes',
                   help='passes arguments to journalctl')
    a.add_argument('config')
    a.add_argument('-t', '--timeout', default=10, help="about execution after TIMEOUT seconds")
    a.add_argument('-v', '--verbose', action='count', default=0)


    args = a.parse_args()
    check = nagiosplugin.Check(
        Journal(params=args, src=args.config),
        nagiosplugin.ScalarContext('warning', warning="0:0", critical="0:1"),
        nagiosplugin.ScalarContext('critical', warning="0:0", critical="0:1"),
        JournalSummary())
    check.main(args.verbose, args.timeout)

if __name__ == '__main__':
    main()



