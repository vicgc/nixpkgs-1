"""fcmanage

High-level system management scripts which are periodiacally called from
a systemd timer: update system configuration from an infrastructure
hydra server or from a local nixpkgs checkout.
"""

from setuptools import setup


test_deps = [
    'pytest',
    'mock',
]


setup(
    name='fc.manage',
    version='2.1',
    description=__doc__,
    url='https://flyingcircus.io',
    author='Christian Theune, Christian Kauhaus, Christian Zagrodnick',
    author_email='mail@flyingcircus.io',
    license='ZPL',
    classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Environment :: Console',
        'License :: OSI Approved :: Zope Public License',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Topic :: System :: Systems Administration',
    ],
    packages=['fc.manage'],
    install_requires=[
        'fc.maintenance',
        'fc.util',
        'requests',
        'click',
    ],
    tests_require=[test_deps],
    setup_requires=['pytest-runner'],
    extras_require={'test': test_deps},
    entry_points={
        'console_scripts': [
            'fc-manage=fc.manage.manage:main',
            'fc-monitor=fc.manage.monitor:main',
            'fc-resize=fc.manage.resize:main',
            'fc-graylog=fc.manage.graylog:main',
        ],
    },
    zip_safe=False,
)
