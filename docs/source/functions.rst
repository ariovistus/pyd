Exposing D functions to python
==============================

The heart of PyD's function wrapping is the `def` template function.

.. literalinclude:: ../../examples/def/example.d
    :language: d

Notes
    * Any function whose return type and parameters types are convertible by
    * All calls to `def` must occur before the call to module_init or py_init
      PyD's type conversion can be wrapped by `def`.
    * `def` can't handle :code:`out`, :code:`ref`, or :code:`lazy` parameters.
    * `def` can't handle functions with c-style variadic arguments
    * `def` *can* handle functions with default and typesafe variadic arguments
    * `def` supports skipping default arguments (on the python side) and will
      automatically fill in any omitted default arguments
    * `def`-wrapped functions can take keyword arguments in python

`def`-wrapped functions can be called in the following ways:

+-----------------------------------------------+----------------------+
| D function                                    | Python call          |
+===============================================+======================+
| :code:`void foo(int i);`                      | | foo(1)             |
|                                               | | foo(i=1)           |
+-----------------------------------------------+----------------------+
| :code:`void foo(int i = 2, double d = 3.14);` | | foo(1, 2.0)        |
|                                               | | foo(d=2.0)         |
|                                               | | foo()              |
+-----------------------------------------------+----------------------+
| :code:`void foo(int[] i...);`                 | | foo(1)             |
|                                               | | foo(1,2,3)         |
|                                               | | foo([1,2,3])       |
|                                               | | foo(i=[1,2,3])     |
+-----------------------------------------------+----------------------+

def template arguments
~~~~~~~~~~~~~~~~~~~~~~

Aside from the required function alias, `def` recognizes a number of
poor-man keyword arguments, as well as a type specifier for the function alias.

.. code-block:: d

    def!(func, void function(int), ModuleName!"mymodl")();

Order is not significant for these optional arguments.

ModuleName
----------

specify the module in which to inject the function

Default: `''`

.. _Docstring: 

Docstring
---------

Specify the docstring to associate with the function

Default: :code:`''`

.. _PyName: 

PyName
------

Specify the name that python will bind the function to

Default: the name of the exposed function
