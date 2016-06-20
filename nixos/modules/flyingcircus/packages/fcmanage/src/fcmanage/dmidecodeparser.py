"""Calculates Memory from dmidecode"""

import string
from subprocess import check_output


def get_paragraph(text, separator='\n'):
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


def get_device(entry):
    params = [x.strip().split(':') for x in entry]
    # need to remove elements with no values, or too many
    params = [x for x in params if len(x) == 2]
    return dict(params)


def calc_mem(modules):
    total = 0
    for m in modules:
        total += int(''.join(ch for ch in m['Size'] if ch in string.digits))
    return total


def main():
    modules = []
    try:
        dmidecode = check_output(['dmidecode', '-q']).decode()
    except Exception:
        import sys
        sys.exit(1)
    for entry in get_paragraph(dmidecode.split('\n')):
        for line in entry:
            if 'Memory Device' in line:
                modules.append(get_device(entry))
    return calc_mem(modules)


if __name__ == '__main__':
    main()
