Embedding Python in D
=====================

A D program with embedded python might look like

.. literalinclude:: ../../examples/simple_embedded/hello.d
    :language: d

Some Notes:
    * you must call py_init to initialize the python interpreter before making any calls to python.
    * `pyd.embedded` contains some goodies for calling python from D code
    * it's even possible to expose D functions to python, then invoke them in python code in D code! (see examples/pyind)

Once again, we use distutils to compile this code using the special command `pydexe`:

.. literalinclude:: ../../examples/simple_embedded/setup.py

.. code-block:: bash

    $ python setup.py install
    $ ./hello
    1 + 2

InterpContext
-------------

One of the goodies in `pyd.embedded` is InterpContext - a class that wraps a python scope and provides some conveniences for data transfer:

.. literalinclude:: ../../examples/interpcontext/interpcontext.d
    :language: d

Miscellaneous
-------------

call stack is not deep enough
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Certain python modules (i.e. :code:`inspect`) expect python to have a nonempty
call stack. This seems not to be the case in embedded python. To work around
this, use :code:`InterpContext.pushDummyFrame`:

.. code-block:: d

    context.pushDummyFrame();
    py_stmts("import inspect");
    context.popDummyFrame();
