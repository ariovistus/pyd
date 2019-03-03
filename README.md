[![build-status-badge]][build-status]
[![docs-badge]][docs]
[![pypi-version]][pypi]
[![license-badge]][license]

# PyD

PyD provides seamless interoperability between Python and the D programming language.

# Usage

To use with dub, either specify the relevant subConfiguration for your python version,
or run `source pyd_set_env_vars.sh <your python>` on linux or
`pyd_set_env_vars.bat <your python>` on windows to set the relevant environment variables
and use the `env` subConfiguration.

These scripts can be run from any directory, but to facilitate using PyD as a dependency
pulled from the dub registry you can run `dub run pyd:setup` to copy them to the current
directory for use, e.g. given you are in the current directory of a package that depends
on pyd, run `dub run pyd:setup` followed by `source pyd_set_env_vars.sh`, then build
your package as normal.

# Requirements

## Python

CPython 2.6+

## D Compilers

* DMD, LDC fe2.065+
* GDC fe2.065+, embedding only (GDC still doesn't have shared library support!)

Note all D compilers are based on DMD's front end, so while LDC and GDC have
their own versioning schemes, I only pay attention to the front end version.


[build-status-badge]: https://travis-ci.org/ariovistus/pyd.svg?branch=master
[build-status]: https://travis-ci.org/ariovistus/pyd
[docs-badge]: https://readthedocs.org/projects/pyd/badge/
[docs]: http://pyd.readthedocs.org/
[pypi-version]: https://img.shields.io/pypi/v/pyd.svg
[pypi]: https://pypi.python.org/pypi/pyd
[license-badge]: https://img.shields.io/pypi/l/pyd.svg
[license]: https://pypi.python.org/pypi/pyd/
