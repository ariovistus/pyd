Type Conversion
===============

PyD provides `d_to_python` and `python_to_d` for converting types to and from 
python. These functions almost always do a copy. If you want reference semantics, use `PydObject`.

D to Python
-----------

==============================  ======================
*D Type*                        *Python Type*
------------------------------  ----------------------
bool                            bool
Any integral type               bool
BigInt                          long (int in python3)
float, double, real             float
std.complex.Complex             complex
std.datetime.Date               datetime.date
std.datetime.DateTime           datetime.datetime
std.datetime.SysTime            datetime.datetime
std.datetime.Time               datetime.time
string                          str
dynamic array                   list
static array                    list
std.typecons.Tuple              tuple
associative array               dict
delegates or function pointers  callable object
a wrapped class                 wrapped type
a wrapped struct                wrapped type
pointer to wrapped struct       wrapped type
PydObject                       wrapped object's type
PyObject*                       object's type
==============================  ======================


Python to D
-----------

======================          ===============================================
*Python Type*                   *D Type*
----------------------          -----------------------------------------------
Any type                        PyObject*, PydObject
Wrapped struct                  Wrapped struct, pointer to wrapped struct
Wrapped class                   Wrapped class
Any callable                    delegate
array.array                     dynamic or static array
Any iterable                    dynamic or static array, PydInputRange
str                             string or char[]
tuple                           std.typecons.Tuple
complex                         std.complex.Complex
float                           float, double, real
int, long                       Any integral type
bool                            bool
buffer                          dynamic or static array (with many dimensions!) 
datetime.date                   std.datetime.Date, std.datetime.DateTime, std.datetime.SysTime
datetime.datetime               std.datetime.Date, std.datetime.DateTime, std.datetime.SysTime, std.datetime.Time
datetime.time                   std.datetime.Time
======================          ===============================================

Numpy
-----

Numpy arrays implement the `buffer protocol <https://docs.python.org/3/c-api/buffer.html>`__, which PyD can efficiently convert to D arrays.

To convert a D array to a numpy array, use `pyd.extra.d_to_python_numpy_ndarray`.

Extending PyD's type conversion
-------------------------------

PyD's type conversion can be extended using `ex_d_to_python` and `ex_python_to_d`. Each takes a delegate or function pointer that performs the conversion.

Extensions will only be used if PyD's regular type conversion mechanism fails.
This would usually happen when an exposed function takes or returns an unwrapped
class or struct.

.. literalinclude:: ../../examples/extend_type_conversion/example.d
    :language: d

results:

.. code-block:: python
    
    example.foo()
    example.bar(20)

.. code-block:: bash
    
    12
    S(20)
