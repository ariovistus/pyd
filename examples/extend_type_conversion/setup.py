from pyd.support import setup, Extension

projName = 'example'

setup(
    name=projName,
    version='0.1',
    ext_modules=[
    Extension(projName, ['example.d'],
        build_deimos=True,
        d_lump=True
        )
    ],
)
