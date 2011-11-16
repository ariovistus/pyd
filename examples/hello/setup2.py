from celerid.support import setup, Extension

projName = 'hello2'

setup(
    name=projName,
    version='0.1',
    ext_modules=[
        Extension(projName, ['hello2.d'])
    ],
)
