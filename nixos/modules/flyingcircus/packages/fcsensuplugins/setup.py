"""Collection of FC-specific monitoring checks."""

from setuptools import setup


setup(
    name='fc.sensuplugins',
    version='1.0',
    description=__doc__,
    url='https://github.com/flyingcircus/nixpkgs',
    author='Christian Kauhaus, Maksim Bronsky',
    author_email='kc@flyingcircus.io, mb@flyingcircus.io',
    license='ZPL',
    classifiers=[
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
    ],
    packages=['fc.sensuplugins'],
    install_requires=['nagiosplugin'],
    entry_points={
        'console_scripts': [
            'check_disk=fc.sensuplugins.disk:main',
            'check_journal=fc.sensuplugins.journal:main'
        ],
    },
)
