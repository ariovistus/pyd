PydObject
=========

PydObject wraps a PyObject*. It handles the python reference count for you, and generally provides seamless access to the python object.

.. literalinclude:: ../../examples/pydobject/example.d
    :language: d

Notes:
    * Due to some residual awkwardness with D's properties, member functions 
      with zero or one arguments must be accessed through `method`, 
      `method_unpack`, etc. Member functions with two or more arguments can be
      called directly.
    * Calling a member function will result in another PydObject; call 
      :code:`to_d!T()` to convert it to a D object.
    * PydObjects are callable
    * PydObjects are iterable
    * PydObjects support the usual operator overloading.

Buffer protocol
---------------

PydObject exposes a near-raw interface to the buffer protocol which can be 
used to e.g. read values from a numpy array without copying the entire thing 
into a D data structure.
