from celerid.support import setup, Extension

projName = 'inherit'

setup(
    name=projName,
    version='0.1',
    ext_modules=[
        Extension(projName, ['inherit.d'])
    ],
)
