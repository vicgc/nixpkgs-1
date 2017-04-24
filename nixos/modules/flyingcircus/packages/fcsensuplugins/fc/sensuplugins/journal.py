#!python3
""" Journal check.

Takes a set of regular expression, tries to match them with the output of
journalctl and if positive prints them.
"""

import argparse
import functools
import logging
import nagiosplugin
import os
import re
import requests
import shlex
import subprocess
import yaml


PATTERN_SECTIONS = [
    'warningpatterns', 'warningexceptions',
    'criticalpatterns', 'criticalexceptions',
]
_log = logging.getLogger('nagiosplugin')


class Journal(nagiosplugin.Resource):

    def __init__(self, journalctl, patterns):
        self.journalctl = journalctl
        self.pattern_yaml = patterns

        self.warnings = []
        self.criticals = []

    @staticmethod
    def sanitize_environment():
        try:
            del os.environ['LC_ALL']
            del os.environ['LANGUAGE']
        except KeyError:
            pass
        os.environ['LANG'] = 'en_US.utf8'

    def load_patterns(self):
        response = requests.get(self.pattern_yaml)
        patterns = yaml.safe_load(response.content)
        _log.debug('patterns:\n%r', patterns)
        compiled = {}
        for section in PATTERN_SECTIONS:
            compiled[section] = [re.compile(p) for p in patterns[section]]
        return compiled

    def read_log(self):
        self.sanitize_environment()
        try:
            log = subprocess.check_output(shlex.split(self.journalctl)).\
                decode('utf-8', errors='replace').strip().splitlines()
        except subprocess.CalledProcessError as e:
            ret = e.returncode
            # journalctl returns 256, if the the filtered output is empty
            # we may exit early
            if ret == 256:
                return([], [])
            # systemd < 223 returns stupid output in case of zero entries
            # zero entries == ok
            elif ret == 1 and 'timestamp' in e.output.decode():
                return([], [])
            else:
                raise
        _log.debug('complete log:\n%s', log)
        return log

    def filter(self, log, type_, matchpatterns, exceptionpatterns):
        """Returns matching (include/except) log lines."""
        if not log or not matchpatterns:
            return []

        # create a list of match candidates by applying the rules
        hits = [entry
                for rule in matchpatterns
                for entry in log
                if rule.search(entry)]
        if hits:
            _log.info('%s hits (w/o exceptions):\n%s', type_, '\n'.join(hits))

        # reduce them by exceptions
        if hits and exceptionpatterns:
            hits = functools.reduce(
                lambda hit, exc: [h for h in hit if not exc.search(h)],
                exceptionpatterns, hits)

        return hits

    def find_hits(self):
        patterns = self.load_patterns()
        log = self.read_log()

        warning_hits = self.filter(
            log, 'warning', patterns['warningpatterns'],
            patterns['warningexceptions'])
        critical_hits = self.filter(
            log, 'critical', patterns['criticalpatterns'],
            patterns['criticalexceptions'])
        return (warning_hits, critical_hits)

    def probe(self):
        self.warnings, self.criticals = self.find_hits()

        return [nagiosplugin.Metric('warning', len(self.warnings), min=0),
                nagiosplugin.Metric('critical', len(self.criticals), min=0)]


class JournalSummary(nagiosplugin.Summary):

    def ok(self, results):
        return 'no errors found'

    def problem(self, results):
        return '{} critical line(s) found, {} warning line(s) found'.format(
            results['critical'].metric.value,
            results['warning'].metric.value)

    def verbose(self, results):
        res = []
        if results['critical'].metric.value:
            res += (['*** critical hits ***'] +
                    results['critical'].resource.criticals)
        if results['warning'].metric.value:
            res += (['*** warning hits ***'] +
                    results['warning'].resource.warnings)
        return '\n'.join(res)


@nagiosplugin.guarded
def main():
    a = argparse.ArgumentParser()
    a.add_argument('-j', '--journalctl', dest='journalctl',
                   default='journalctl --no-pager --output=short '
                   '--since=-10minutes',
                   help='journalctl invocation (default: "%(default)s")')
    a.add_argument('CONFIG', help='URL to log check rules yaml')
    a.add_argument('-t', '--timeout', default=10,
                   help='about execution after TIMEOUT seconds')
    a.add_argument('-v', '--verbose', action='count', default=0)

    args = a.parse_args()
    check = nagiosplugin.Check(
        Journal(args.journalctl, args.CONFIG),
        nagiosplugin.ScalarContext('warning', warning='0:0'),
        nagiosplugin.ScalarContext('critical', critical='0:0'),
        JournalSummary())
    check.main(args.verbose, args.timeout)


if __name__ == '__main__':
    main()
