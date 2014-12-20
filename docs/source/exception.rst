Exception Wrapping
==================

The raw Python/C API has a protocol for allowing C extensions to use Python's exception mechanism. As a user of PyD, you should never have to deal with this protocol. Instead, use PyD's mechanisms for translating a Python exception into a D exception and vice versa.


:code:`handle_exception`
------------------------ 
check if a Python exception has been set, and if it has, throw a 
:code:`PythonException`. Clear the Python error code.

:code:`exception_catcher`
------------------------- 
wrap a D delegate and set a Python error code if a D exception occurs. 
Returns a python-respected "invalid" value (null or -1), or the result of 
the delegate if nothing was thrown.

Notes
    * If your code interfaces with python directly, you should probably 
      wrap it with :code:`exception_catcher` (uncaught D exceptions will crash
      the python interpreter).
    * All wrapped functions, methods, constructors, etc, handle D and 
      python exceptions already.
