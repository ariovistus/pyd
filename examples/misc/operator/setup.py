from distutils.core import setup, Extension

module1 = Extension("x", sources = ['xclass.c'])

setup(
        name = "x",
        version = '1.0',
        description = "eat a taco",
        ext_modules = [module1]);
