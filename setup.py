# Note:  This setup.py is for CeleriD itself, not for an extension written in
# D.

import distutils.core, os, sys
import os.path

import build_manifest

PACKAGE_NAME = 'pyd'

isSourceDist = 'sdist' in [arg.lower() for arg in sys.argv]

f = open('MANIFEST', 'w')
try:
    build_manifest.buildManifest(f, True)
finally:
    f.close()

includedPaths, excludedPaths = build_manifest.listFiles(isSourceDist)

allFiles = [
    build_manifest.convertPathToDistutilsStandard(path)
    for path in includedPaths
]

# Only Python code files *within the pyd package* should go into
# packageFiles (Python code files in examples shouldn't).  A module named
# 'X.py' should later appear in packageModules as 'pyd.X'.
packageCodeFiles = [f for f in allFiles if f.endswith('.py') and '/' not in f]
packageDataFiles = [f for f in allFiles if f not in packageCodeFiles]

packageModules = [
    PACKAGE_NAME + '.' + os.path.splitext(f)[0]
    for f in packageCodeFiles
]

README="""
PyD

PyD provides seamless interoperability between python and the D programming language

Project at https://github.com/ariovistus/pyd

Docs at http://pyd.readthedocs.org/

more about D: http://dlang.org/
"""

distutils.core.setup(
    name=PACKAGE_NAME,
    package_dir={PACKAGE_NAME: os.curdir},
    packages=[PACKAGE_NAME],
    package_data={PACKAGE_NAME: packageDataFiles},
    py_modules=packageModules,

    version=open('version.txt').read().strip(),
    url='https://github.com/ariovistus/pyd',
    description="Interoperability between python and the D programming language",
    long_description=README,
    maintainer='Ellery Newcomer',
    maintainer_email='ellery-newcomer@utulsa.edu',
    classifiers=[
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Operating System :: Microsoft :: Windows',
        'Operating System :: POSIX :: Linux',
        #'Programming Language :: D',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.6',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.2',
        'Programming Language :: Python :: 3.3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
    ]
)

