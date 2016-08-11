""" Unit-test for dmidecode parser"""

from fc.manage.dmi_memory import calc_mem, get_paragraph, get_device
import pkg_resources


def test_calc_mem():
    modules = [{'Size': '0MB'},
               {'Size': '512MB'},
               {'Size': '2048    MB'},
               {'Size': '    9096 mb'}]
    res = calc_mem(modules)
    assert res == 11656


def test_get_paragraph():
    with pkg_resources.resource_stream(__name__, 'dmidecode.out') as f:
        dmidecode_output = f.readlines()
    for rows in list(get_paragraph(dmidecode_output)):
        for elem in rows:
            assert elem != ""
            assert elem in dmidecode_output


def test_get_device():
    entry = ['Memory Device',
             'Total Width: Unknown',
             'Type: Ram',
             'Locator: DIMM: 0']
    res = get_device(entry)
    assert res == {'Total Width': ' Unknown', 'Type': ' Ram'}
