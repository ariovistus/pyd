from pyd.support import setup, Extension

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
projName = 'hello2'
setup(
    name=projName,
    version='0.1',
    ext_modules=[
        Extension(projName, ['hello2.d'],
        build_deimos=True,
        d_lump=True,
            )
    ],
)
