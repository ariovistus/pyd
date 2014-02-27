# usage: python setup.py pydexe
import sys
if sys.argv[1] != 'pydexe':
    print( "use pydexe, not %s" % sys.argv[1] )
    sys.exit(1)
from celerid.support import setup, Extension
import platform


maj = int(platform.python_version_tuple()[0])
if maj == 3:
    projName = 'pyind3'
    srcs = ['pyind3.d']
    
elif maj == 2:
    projName = 'pyind'
    srcs = ['pyind.d']
else:
    assert False, "want python 2 or python 3"

setup(
    name=projName,
    version='1.0',
    ext_modules=[
    Extension(projName, srcs,
    build_deimos=True, d_lump=True
        )
    ],
)
