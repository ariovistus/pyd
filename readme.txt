Welcome to Pyd!

Pyd is currently under development, and is still subject to API 
changes (https://bitbucket.org/ariovistus/pyd/wiki/Changes)

Current status: https://bitbucket.org/ariovistus/pyd/wiki/Status

This package is composed of two separate parts:

  * CeleriD - An extension to Python's Distutils that is aware of D.
  * Pyd - A library for D that wraps the Python API.

CeleriD was originally written by David Rushby, and Pyd was written by Kirk
McDonald. Pyd uses a number of additional libraries; see credits.txt for
details. These libraries are contained in the "infrastructure" directory.

INSTALLATION

Normally it is as simple as

    python setup.py install

from the root directory of the project. This will place CeleriD in Python's
site-packages directory, and Pyd lives inside of CeleriD.

For the smoothest of sailing, ensure both D and Python are on the system's PATH.
This is not required, however:

  * On Windows, only the DMD compiler is supported. If it is not found on the
    PATH, CeleriD will check the DMD_BIN environment variable.
  * On Linux, currently the DMD compiler is supported. If it is not found on the
    PATH, CeleriD will check the DMD_BIN environment variable.

Examples of using Pyd may be found in the "examples" directory. For full
documentation, check the wiki: 

https://bitbucket.org/ariovistus/pyd/wiki/Home

