from celerid.support import setup, Extension

projName = 'testdll'

setup(
    name=projName,
    version='0.1',
    ext_modules=[
        Extension(projName, [projName + '.d'], 
            d_lump=True, 
            build_deimos=True)
    ],
  )
