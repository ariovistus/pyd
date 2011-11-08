from celerid.support import setup, Extension

projName = 'arraytest'

setup(
    name=projName,
    version='0.1',
    ext_modules=[
        Extension(projName, ['arraytest.d'])
    ],
)
