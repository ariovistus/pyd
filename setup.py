# Note:  This setup.py is for CeleriD itself, not for an extension written in
# D.

import distutils.core, os, sys
import os.path

import build_manifest

PACKAGE_NAME = 'celerid'

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

# Only Python code files *within the celerid package* should go into
# packageFiles (Python code files in examples shouldn't).  A module named
# 'X.py' should later appear in packageModules as 'celerid.X'.
packageCodeFiles = [f for f in allFiles if f.endswith('.py') and '/' not in f]
packageDataFiles = [f for f in allFiles if f not in packageCodeFiles]

packageModules = [
    PACKAGE_NAME + '.' + os.path.splitext(f)[0]
    for f in packageCodeFiles
]

distutils.core.setup(
    name=PACKAGE_NAME,
    package_dir={PACKAGE_NAME: os.curdir},
    packages=[PACKAGE_NAME],

    version=open('version.txt').read().strip(),
    url='https://bitbucket.org/ariovistus/pyd',
    maintainer='Ellery Newcomer',
    maintainer_email='ellery-newcomer@utulsa.edu',
    py_modules=packageModules,
    package_data={PACKAGE_NAME: packageDataFiles},
)

