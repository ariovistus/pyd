import pyd.support
from pyd.support import setup, Extension, pydexe_sanity_check

pydexe_sanity_check()
projName = 'make_object'
ext_modules = setup(
    name=projName,
    version='1.0',
    ext_modules=[
        Extension("make_object", ["make_object.d"],
            d_unittest=True,
            build_deimos=True,
            d_lump=True,
        )
    ],
)
