PyD and distutils
=================

PyD provides patches to distutils so it can use DMD, LDC, and GDC.

.. seealso::
    
    `distutils <https://docs.python.org/2/library/distutils.html#module-distutils>`__


Mostly, this consists of a different :code:`setup` that must be called, and a different :code:`Extension` that must be used:

.. literalinclude:: ../../examples/hello/setup.py

Command line flags
~~~~~~~~~~~~~~~~~~

compiler
--------
Specify the D compiler to use. Expects one of dmd, ldc, gdc.

.. code-block:: bash

    python setup.py install --compiler=ldc

Default: dmd


debug
-------
Have the D compiler compile things with debugging information.

.. code-block:: bash

    python setup.py install --debug

Extension arguments
~~~~~~~~~~~~~~~~~~~

In addition to the `arguments <https://docs.python.org/2/distutils/apiref.html#distutils.core.Extension>`__ accepted by distutils' Extension, PyD's `Extension` accepts the following arguments:

version_flags
-------------

A list of strings passed to the D compiler as D version identifiers.

Default: :code:`[]`

debug_flags
-----------

similar to version_flags for D debug identifiers

Default: :code:`[]`

raw_only
--------

When :code:`True`, suppress linkage of all of PyD except the bare C API.

Equivalent to setting `with_pyd` and `with_main` to :code:`False`.

Default: :code:`False`

with_pyd
--------
Setting this flag to :code:`False` suppresses compilation and linkage of PyD. 
`with_main` effectively becomes :code:`False` as well; `PydMain` won't be used 
unless PyD is in use.

Default: :code:`True`

with_main
---------
Setting this flag to :code:`False` suppresses the use of `PydMain`, allowing 
the user to write a C-style init function instead.

Default: :code:`True`

build_deimos
------------
Build object files for deimos headers. Ideally, this should not be necessary; 
however some compilers (\*cough* ldc) try to link to PyObject typeinfo. If you 
get link errors like 

`undefined symbol: _D6deimos6python12methodobject11PyMethodDef6__initZ` 

try setting this flag to :code:`True`.

Default: :code:`False`


optimize
--------
Have D compilers do optimized compilation.

Default: :code:`False`

d_lump
------
Lump compilation of all d files into a single command.

Default: :code:`False`

d_unittest
----------

Have D compilers generate unittest code

Default: :code:`False`

d_property
----------

Have D compilers enable property checks (i.e. trying to call functions without 
parens will result in an error)

Default: :code:`True`

string_imports
--------------

Specify string import files to pass to D compilers. Takes a list of strings 
which are either paths to import files or paths to directories containing 
import files.

Default: :code:`[]`


pydexe
~~~~~~
PyD also provides a custom command to compile D code that embeds python. The 
format of setup.py stays the same.

.. literalinclude:: ../../examples/pyind/setup.py

Mixing C and D extensions
~~~~~~~~~~~~~~~~~~~~~~~~~

It is totally possible. Use PyD's :code:`setup`.

.. literalinclude:: ../../examples/misc/d_and_c/setup.py
