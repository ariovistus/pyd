/**
  Mirror _intobject.h

Integer object interface

PyIntObject represents a (long) integer.  This is an immutable object;
an integer cannot change its value after creation.

There are functions to create new integer objects, to test an object
for integer-ness, and to get the integer value.  The latter functions
returns -1 and sets errno to EBADF if the object is not an PyIntObject.
None of the functions should be applied to nil objects.

The type PyIntObject is (unfortunately) exposed here so we can declare
_Py_TrueStruct and _Py_ZeroStruct in boolobject.h; don't use this.

  Note _intobject has gone away in favor of longobject in python 3.
  */
module deimos.python.intobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.unicodeobject;

version(Python_3_0_Or_Later) {
    // int merged with long in python 3
}else {
extern(C):
// Python-header-file: Include/intobject.h:

/// subclass of PyObject
/// Availability: 2.*
struct PyIntObject {
    mixin PyObject_HEAD;

    /// _
    C_long ob_ival;
}

/// Availability: 2.*
mixin(PyAPI_DATA!"PyTypeObject PyInt_Type");

// D translation of C macro:
/// Availability: 2.*
int PyInt_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, &PyInt_Type);
}
// D translation of C macro:
/// Availability: 2.*
int PyInt_CheckExact()(PyObject* op) {
    return op.ob_type == &PyInt_Type;
}

/// Availability: 2.*
PyObject* PyInt_FromString(char*, char**, int);
/// Availability: 2.*
PyObject* PyInt_FromUnicode(Py_UNICODE*, Py_ssize_t, int);
/// Availability: 2.*
PyObject* PyInt_FromLong(C_long);
version(Python_2_5_Or_Later){
    /// Availability: 2.5, 2.6, 2.7
    PyObject* PyInt_FromSize_t(size_t);
    /// Availability: 2.5, 2.6, 2.7
    PyObject* PyInt_FromSsize_t(Py_ssize_t);

    /// Availability: 2.5, 2.6, 2.7
    Py_ssize_t PyInt_AsSsize_t(PyObject*);
}

/// Availability: 2.*
C_long PyInt_AsLong(PyObject*);
/// Availability: 2.*
C_ulong PyInt_AsUnsignedLongMask(PyObject*);
/// Availability: 2.*
C_ulonglong PyInt_AsUnsignedLongLongMask(PyObject*);

/** Accessible at the Python level as sys.maxint */
C_long PyInt_GetMax();

/// Availability: 2.*
C_ulong PyOS_strtoul(char*, char**, int);
/// Availability: 2.*
C_long PyOS_strtol(char*, char**, int);
version(Python_2_6_Or_Later){
    /// Availability: >= 2.6
    C_long PyOS_strtol(char*, char**, int);

    /** free list api */
    /// Availability: >= 2.6
    int PyInt_ClearFreeList();

    /** Convert an integer to the given base.  Returns a string.
       If base is 2, 8 or 16, add the proper prefix '0b', '0o' or '0x'.
       If newstyle is zero, then use the pre-2.6 behavior of octal having
       a leading "0" */
    /// Availability: >= 2.6
    PyObject* _PyInt_Format(PyIntObject* v, int base, int newstyle);

    /** Format the object based on the format_spec, as defined in PEP 3101
       (Advanced String Formatting). */
    /// Availability: >= 2.6
    PyObject*  _PyInt_FormatAdvanced(PyObject* obj,
            char* format_spec,
            Py_ssize_t format_spec_len);
}


}
