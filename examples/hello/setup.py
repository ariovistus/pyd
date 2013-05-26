from celerid.support import setup, Extension

projName = 'hello'

setup(
    name=projName,
    version='0.1',
    ext_modules=[
    Extension(projName, ['hello.d'],
        build_deimos=True,
        d_lump=True
        )
    ],
)
