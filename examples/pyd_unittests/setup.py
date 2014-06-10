# usage: python setup.py pydexe
import sys
if sys.argv[1] != 'pydexe':
    print( "use pydexe, not %s" % sys.argv[1] )
    sys.exit(1)
from celerid.support import setup, Extension
import platform
maj = platform.python_version_tuple()[0] 

projName = 'pyd_unittests'
exts = [
        'pydobject','make_object','embedded','func_wrap','class_wrap',
        'def','struct_wrap', 'typeinfo', 'const', 'extra', 
];

string_imports = {
        'func_wrap': ["important_message.txt"],
        }

ext_modules = setup(
    name=projName,
    version='1.0',
    ext_modules=[
        Extension(e, [e+".d"],
            d_unittest=True,
            build_deimos=True,
            d_lump=True,
            string_imports = string_imports.get(e, [])
            )
            for e in exts 
    ],
)
