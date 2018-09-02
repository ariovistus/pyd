from distutils.core import Extension as cExtension
from pyd.support import setup, Extension

module1 = Extension("coffsets", sources = ['coffsets.c'])
module2 = Extension("doffsets", sources = ['doffsets.d'], build_deimos=True, d_lump=True)

setup(
    name = "x",
    version = '1.0',
    description = "eat a taco",
    ext_modules = [
        module1,
        module2
    ]
);
