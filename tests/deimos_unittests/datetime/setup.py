# usage: python setup.py pydexe
from pyd.support import setup, Extension, pydexe_sanity_check
import platform

pydexe_sanity_check()
projName = "datetime"
setup(
    name=projName,
    version='1.0',
    ext_modules=[
        Extension("datetime", ['datetime.d'],
            build_deimos=True,
            d_lump=True,
            d_unittest=True
        ),
    ],
)
