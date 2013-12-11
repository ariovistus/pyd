# usage: python setup.py pydexe
import sys
if sys.argv[1] != 'pydexe':
    print( "use pydexe, not %s" % sys.argv[1] )
    sys.exit(1)
from celerid.support import setup, Extension
import platform
projName = "deimos_unittests"

setup(
    name=projName,
    version='1.0',
    ext_modules=[
    Extension("link", ['link.d'],
    build_deimos=True,
    d_lump=True,
    d_unittest=True
        ),
    Extension("object_", ['object_.d'],
    build_deimos=True,
    d_unittest=True,
    d_lump=True
        ),
    Extension("datetime", ['datetime.d'],
    build_deimos=True,
    d_unittest=True,
    d_lump=True
        )
    ],
)
