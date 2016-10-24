from pyd.support import setup, Extension

projName = 'libmarsv5camera_py'

setup(
        name=projName,
        version='0.1',
        ext_modules=[
                Extension(projName, sources=['marscamera_py.d', 'marscamera_c_interface.d'],
                          build_deimos=True,
                          d_lump=True
                          )
                ],
        )
