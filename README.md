[![build-status-badge]][build-status]
[![docs-badge]][docs]
[![pypi-version]][pypi]
[![license-badge]][license]

# PyD

PyD provides seamless interoperability between Python and the D programming language.

# Usage

To use with dub, either specify the relevant subConfiguration, or run
`source set_env_vars.sh <your python>` on linux or
`set_env_vars.bat <your python>` on windows to set the relevant environment variables
and use the `env` subConfiguration

# Requirements

## Python

CPython 2.6+

## D Compilers

* DMD, LDC fe2.065+
* GDC fe2.065+, embedding only (GDC still doesn't have shared library support!)

Note all D compilers are based on DMD's front end, so while LDC and GDC have
their own verisoning schemes, I only pay attention to the front end version.


[build-status-badge]: https://travis-ci.org/ariovistus/pyd.svg?branch=master
[build-status]: https://travis-ci.org/ariovistus/pyd
[docs-badge]: https://readthedocs.org/projects/pyd/badge/
[docs]: http://pyd.readthedocs.org/
[pypi-version]: https://img.shields.io/pypi/v/pyd.svg
[pypi]: https://pypi.python.org/pypi/pyd
[license-badge]: https://img.shields.io/pypi/l/pyd.svg
[license]: https://pypi.python.org/pypi/pyd/
