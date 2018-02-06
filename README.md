[![build-status-badge]][build-status]
[![docs-badge]][docs]
[![pypi-version]][pypi]
[![license-badge]][license]

# PyD

PyD provides seamless interoperability between Python and the D programming language.

# Requirements

## Python

CPython 2.6+

## D Compilers

* DMD, LDC fe2.065+
* GDC fe2.065+, embedding only (GDC still doesn't have shared library support!)

Note all D compilers are based on DMD's front end, so while LDC and GDC have
their own verisoning schemes, I only pay attention to the front end version.

## Boilerplate

On Linux the project must be linked with an object file after compiling infrastructure/d/so_ctor.c.

On both Linux and Windows a D source file must exist in the project with the following lines:

```d
import pyd.boilerplate: boilerplate;
mixin(boilerplateMixinStr());
```

[build-status-badge]: https://travis-ci.org/ariovistus/pyd.svg?branch=master
[build-status]: https://travis-ci.org/ariovistus/pyd
[docs-badge]: https://readthedocs.org/projects/pyd/badge/
[docs]: http://pyd.readthedocs.org/
[pypi-version]: https://pypip.in/version/pyd/badge.svg
[pypi]: https://pypi.python.org/pypi/pyd
[license-badge]: https://pypip.in/license/pyd/badge.svg
[license]: https://pypi.python.org/pypi/pyd/
