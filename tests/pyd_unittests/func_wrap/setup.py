import pyd.support
from pyd.support import setup, Extension, pydexe_sanity_check

pydexe_sanity_check()
projName = 'func_wrap'
ext_modules = setup(
    name=projName,
    version='1.0',
    ext_modules=[
        Extension("func_wrap", ["func_wrap.d"],
            d_unittest=True,
            build_deimos=True,
            d_lump=True,
            string_imports = ['important_message.txt'],
        )
    ],
)
