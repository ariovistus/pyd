from pyd.support import setup, Extension

projName = 'hello_w_libs'

setup(
    name=projName,
    version='0.1',
    ext_modules=[
    Extension(projName, ['hello.d'],
        build_deimos=True,
        d_lump=True,
        include_dirs=['libdir1', 'libdir2'],
        library_dirs=['libdir1', 'libdir2'],
        libraries=['lib1', 'lib2']
        )
    ],
)
