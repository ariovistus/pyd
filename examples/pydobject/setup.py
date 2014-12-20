from pyd.support import setup, Extension, pydexe_sanity_check

pydexe_sanity_check()
projName = 'example'
setup(
    name=projName,
    version='1.0',
    ext_modules=[
        Extension(projName, ['example.d'],
            build_deimos=True, d_lump=True
        )
    ],
)
