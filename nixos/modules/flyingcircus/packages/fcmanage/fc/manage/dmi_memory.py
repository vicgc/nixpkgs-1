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
    """Extract device info which is always represented as key-value"""
    params = [x.strip().split(':') for x in entry]
    # extract lines which consist exactly two elements
    return dict(x for x in params if len(x) == 2)


def calc_mem(modules):
    total = 0
    for m in modules:
        total += int(''.join(ch for ch in m['Size'] if ch in string.digits))
    return total


def main():
    modules = []
    dmidecode = check_output(['dmidecode', '-q']).decode()
    for entry in get_paragraph(dmidecode.split('\n')):
        for line in entry:
            if 'Memory Device' in line:
                modules.append(get_device(entry))
    return calc_mem(modules)
