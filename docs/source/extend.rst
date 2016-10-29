Extending Python with D
=======================

PyD supports building python modules with D.

Basics
------
A minimal working PyD module looks something like

.. literalinclude:: ../../examples/hello/hello.d
    :language: d

This code imports the components of pyd, and provides the initializer function that python will call when it loads your module. It also exposes `hello` to python.

Some notes:
    * `def` must be called before `module_init`. `class_wrap` must be called after `module_init`.
    * PydMain will catch any thrown D exceptions and safely pass them to Python.

This extension is then built the usual way with distutils, except PyD provides some patches to support D compilers:

.. literalinclude:: ../../examples/hello/setup.py

.. code-block:: bash

    $ python setup.py install

Usage:

.. code-block:: python

    import hello
    hello.hello()
