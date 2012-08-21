from celerid.support import setup, Extension

projName = 'wrap'

setup(
    name=projName,
    version='0.1',
    ext_modules=[
        Extension(projName, ['wraptest.d'])
    ],
)
