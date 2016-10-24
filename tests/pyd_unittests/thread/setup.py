import pyd.support
from pyd.support import setup, Extension, pydexe_sanity_check

pydexe_sanity_check()
projName = 'thread'
ext_modules = setup(
    name=projName,
    version='1.0',
    ext_modules=[
        Extension("thread", ["thread.d"],
            d_unittest=True,
            build_deimos=True,
            d_lump=True,
        )
    ],
)
