Welcome to Pyd!

Pyd is currently under development, and is in the middle of API 
changes (https://bitbucket.org/ariovistus/pyd/wiki/Changes)

This package is composed of two separate parts:

  * CeleriD - An extension to Python's Distutils that is aware of D.
  * Pyd - A library for D that wraps the Python API.

CeleriD was originally written by David Rushby, and Pyd is written by Kirk
McDonald. Pyd uses a number of additional libraries; see credits.txt for
details. These libraries are contained in the "infrastructure" directory.

INSTALLATION

In the easiest case, you just need to say:

    python setup.py install

while in the root directory of the project. This will place CeleriD in Python's
site-packages directory, and Pyd lives inside of CeleriD.

The easiest time will be had if both D and Python are on the system's PATH.
This is not required, however:

  * On Windows, only the DMD compiler is supported. If it is not found on the
    PATH, CeleriD will check the DMD_BIN environment variable.
  * On Linux, currently the LDC compiler is supported. If it is not found on the
    PATH, CeleriD will check the LDC_BIN environment variable.

Examples of using Pyd may be found in the "examples" directory. For full
documentation, check the wiki: 

https://bitbucket.org/ariovistus/pyd/wiki/Home

