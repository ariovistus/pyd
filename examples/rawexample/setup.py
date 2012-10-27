from celerid.support import setup, Extension

projName = 'rawexample'

setup(
    name=projName,
    version='0.1',
    ext_modules=[
        Extension(projName, ['rawexample.d'], raw_only=True, build_deimos=True)
    ],
)
