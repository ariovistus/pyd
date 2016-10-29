from pyd.support import setup, Extension, pydexe_sanity_check

pydexe_sanity_check()
projName = 'interpcontext'
setup(
    name=projName,
    version='1.0',
    ext_modules=[
        Extension(projName, ['interpcontext.d'],
            build_deimos=True, d_lump=True
        )
    ],
)
