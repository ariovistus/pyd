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
'pydobject','make_object','embedded','func_wrap','class_wrap','def','struct_wrap'
        ];
string_imports = {
        'func_wrap': ["important_message.txt"]
        }
def ext(e):
    if maj == "3":
        return "%s3" % e
    elif maj == "2":
        return e
    else:
        assert False, "want python 2 or python 3"

ext_modules = setup(
    name=projName,
    version='1.0',
    ext_modules=[
        Extension(ext(e), [ext(e)+".d"],
            d_unittest=True,
            string_imports = string_imports.get(e, [])
            )
            for e in exts 
    ],
)
