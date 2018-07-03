Exposing D classes to python
============================

The heart of PyD's class wrapping features is the `class_wrap`
function template.

Member wrapping
---------------

===================   ===============================   ===================
Python member type    D member type                     PyD Param
-------------------   -------------------------------   -------------------
instance function     instance function                 Def!(Foo.fun)
static function       static function                   StaticDef!(Foo.fun)
property              instance function or property     Property!(Foo.fun)
instance field        instance field                    Member!(fieldname)
constructor           constructor                       Init!(Args...)
===================   ===============================   ===================

Notes
    * `Def` and `StaticDef` behave very much like `def`
    * `Init` doesn't take named parameters
    * `Member` takes a string, not an alias

Def template arguments
----------------------

Docstring
~~~~~~~~~~

See :ref:`Docstring`

PyName
~~~~~~~~~~

See :ref:`PyName`

StaticDef template arguments
----------------------------

Docstring
~~~~~~~~~~

See :ref:`Docstring`

PyName
~~~~~~~~~~

See :ref:`PyName`

Property template arguments
---------------------------

Docstring
~~~~~~~~~~

See :ref:`Docstring`

PyName
~~~~~~~~~~

See :ref:`PyName`

.. _Mode:

Mode
~~~~~~~~~~

Specify whether property is read-only, write-only, or read-write.

Possible values: :code:`"r"`, :code:`"w"`, :code:`"rw"`, :code:`""`

When :code:`""`, determine mode based on availability of getter and setter
forms.

Default: :code:`""`

Member template arguments
-------------------------

Mode
~~~~

See :ref:`Mode`

Operator Overloading
--------------------

======================================================================================================================================= ==================  ==================
Operator                                                                                                                                D function          PyD Param
--------------------------------------------------------------------------------------------------------------------------------------- ------------------  ------------------
:code:`+` :code:`-` :code:`*` :code:`/` :code:`%` :code:`^^` :code:`<<` :code:`>>` :code:`&` :code:`^` :code:`|` :code:`~`              opBinary!(op)       OpBinary!(op)
:code:`+` :code:`-` :code:`*` :code:`/` :code:`%` :code:`^^` :code:`<<` :code:`>>` :code:`&` :code:`^` :code:`|` :code:`~` :code:`in`   opBinaryRight!(op)  OpBinaryRight!(op)
:code:`+=` :code:`-=` :code:`*=` :code:`/=` :code:`%=` :code:`^^=` :code:`<<=` :code:`>>=` :code:`&=` :code:`^=` :code:`|=` :code:`~=`  opOpAssign!(op)     OpAssign!(op)
:code:`+` :code:`-` :code:`~`                                                                                                           opUnary!(op)        OpUnary!(op)
:code:`<` :code:`<=` :code:`>` :code:`>=`                                                                                               opCmp               OpCompare!()
:code:`a[i]`                                                                                                                            opIndex             OpIndex!()
:code:`a[i] = b`                                                                                                                        opIndexAssign       OpIndexAssign!()
:code:`a[i .. j]` (python :code:`a[i:j]`)                                                                                               opSlice             OpSlice!()
:code:`a[i .. j] = b` (python :code:`a[i:j] = b`)                                                                                       opSliceAssign       OpSliceAssign!()
:code:`a(args)`                                                                                                                         opCall              OpCall!(Args)
:code:`a.length` (python :code:`len(a)`)                                                                                                length              Len!()
======================================================================================================================================= ==================  ==================

Notes on wrapped operators
    * only one overload is permitted per operator; however OpBinary and OpBinaryRight may "share" an operator.
    * PyD only supports opSlice, opSliceAssign if both of their two indices are
      implicitly convertable to Py_ssize_t. This is a limitation of the
      Python/C API. Note this means the zero-argument form of opSlice
      (:code:`foo[]`) cannot be wrapped.
    * :code:`~`, :code:`~=`: Python does not have a dedicated array
      concatenation operator.
      :code:`+` is reused for this purpose. Therefore, odd behavior may result
      with classes that overload both :code:`+` and :code:`~`. The Python/C API
      does consider addition and concantenation to be distinct operations,
      though.
    * :code:`in`: Semantics vary slightly. In python, :code:`in` is a
      containment test and retursn a bool. In D, by convention
      :code:`in` is a lookup, returning a pointer or null. PyD will check the
      boolean result of a call to the overload and return that value to Python.


Iterator wrapping
-----------------

A wrapped class can be make iterable in python by supplying defs with the
python names:

    * :code:`__iter__`, which should return :code:`this`.
    * :code:`next`, which should return the next item, or null to signal
      termination. Signature must be :code:`PyObject* next()`.

Alternatively, you can supply a single :code:`__iter__` that returns a Range.


Inheritance
-----------
Wrapped classes can be extended in python and the resulting instances can be 
passed back to D. By default, `class_wrap` ensures these instances behave as 
expected with regard to member overrides. This functionality comes at the cost 
of being able to wrap `pure`, `trusted`, `safe`, and `nothrow` methods. If this 
is not desired, it can be turned off by passing `NoInherit` to class_wrap.
