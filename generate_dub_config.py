import json
import six
import sys
import platform
import os.path
from collections import OrderedDict
from pyd.patch_distutils import new_compiler
from distutils.command.build_ext import build_ext
from distutils.dist import Distribution

help = "specify compiler (dmd, ldc, or gdc)"
ext_help = "specify we are building a python extension"
default = 'dmd'

if six.PY2:
    from optparse import OptionParser
    parser = OptionParser()
    parser.add_option("--compiler", dest="compiler", default=default, help=help)
    parser.add_option("--as-extension", dest="extension", default=False, help=ext_help)
    (options, args) = parser.parse_args()
else:
    from argparse import ArgumentParser
    parser = ArgumentParser("""Generates dub configurations for the python instance that invokes this script.
    """)
    parser.add_argument("--compiler", default=default, help=help)
    parser.add_argument("--as-extension", dest="extension", action='store_true', default=False, help=ext_help)
    options = parser.parse_args()

compiler = new_compiler(options.compiler)
compiler.build_exe = not options.extension

class MockExt:
    def __init__(self):
        self.libraries = []
ext = build_ext(Distribution())

libraries = ext.get_libraries(MockExt())
lib_file = compiler._lib_file([])
if lib_file:
    lib_file = os.path.basename(lib_file).replace(compiler.static_lib_extension, "")
    if sys.platform == 'win32':
        libraries.append(os.path.join('$PYD_PACKAGE_DIR','infrastructure', 'windows', lib_file))
if __name__ == '__main__':
    config =  OrderedDict()
    config['name'] = "python%s%s" % platform.python_version_tuple()[0:2]
    config['versions'] = compiler.all_versions()
    config['libs'] = libraries

    print (json.dumps(config, indent=4))
