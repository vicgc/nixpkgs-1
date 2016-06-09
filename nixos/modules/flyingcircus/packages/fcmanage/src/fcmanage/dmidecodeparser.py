"""Calculates Memory from dmidecode"""

import string
from subprocess import check_output


def paragraph(text, separator='\n'):
    paragraph = []

    for line in text:
        if line == separator:
            if paragraph:
                yield paragraph
                paragraph = []
        else:
            paragraph.append(line)
    if paragraph:
        yield paragraph


def get_device(dmidecode):
        params = [x.strip().split(':') for x in dmidecode]
        # need to remove elements with no values, or too many
        params = [x for x in params if len(x) == 2]
        return dict(params)


def calc_mem(modules):
    sum = 0
    for m in modules:
        sum += int(filter(lambda x: x in string.digits, m['Size']))
    return sum


def main():
    modules = []
    try:
        dmidecode = check_output(['dmidecode', '-q']).decode().split('\n')
    except Exception:
        # XXX logging?
        import sys
        sys.exit(1)
        pass
    for entry in paragraph(dmidecode):
        for line in entry:
            if 'Memory Device' in line:
                modules.append(get_device(entry))
    return calc_mem(modules)


if __name__ == '__main__':
    main()
