from pyd.support import setup, Extension

projName = 'hello'

setup(
    name=projName,
    version='0.1',
    ext_modules=[
        Extension(projName, ['hello.d'],
            extra_compile_args=['-w'],
            build_deimos=True,
            d_lump=True
        )
    ],
)
