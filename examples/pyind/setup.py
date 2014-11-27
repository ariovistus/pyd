# usage: python setup.py pydexe
import sys
if sys.argv[1] != 'pydexe':
    print( "use pydexe, not %s" % sys.argv[1] )
    sys.exit(1)
from celerid.support import setup, Extension
import platform


maj = int(platform.python_version_tuple()[0])
projName = 'pyind'
srcs = ['pyind.d']

setup(
    name=projName,
    version='1.0',
    ext_modules=[
    Extension(projName, srcs,
    build_deimos=True, d_lump=True
        )
    ],
)
