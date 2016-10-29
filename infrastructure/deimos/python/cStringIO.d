/**
  Mirror _cStringIO.h

  This header provides access to _cStringIO objects from C.
  Functions are provided for calling _cStringIO objects and
  macros are provided for testing whether you have _cStringIO
  objects.

  Before calling any of the functions or macros, you must initialize
  the routines with:

    PycString_IMPORT()

  This would typically be done in your init function.

  Note _cStringIO.h goes away in python 3
  */
module deimos.python.cStringIO;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.cobject;

version(Python_3_0_Or_Later) {
}else{
extern(C):
// Python-header-file: Include/cStringIO.h:

/// Availability: 2.*
PycStringIO_CAPI* PycStringIO = null;

/// Availability: 2.*
PycStringIO_CAPI* PycString_IMPORT()() {
    if (PycStringIO == null) {
        PycStringIO = cast(PycStringIO_CAPI *)
            PyCObject_Import("cStringIO", "cStringIO_CAPI");
    }
    return PycStringIO;
}

/** Basic functions to manipulate cStringIO objects from C */
/// Availability: 2.*
struct PycStringIO_CAPI {
    /** Read a string from an input object.  If the last argument
    is -1, the remainder will be read.
    */
    int function(PyObject*, char**, Py_ssize_t) cread;
    /** Read a line from an input object.  Returns the length of the read
    line as an int and a pointer inside the object buffer as char** (so
    the caller doesn't have to provide its own buffer as destination).
    */
    int function(PyObject*, char**) creadline;
    /** Write a string to an output object*/
    int function(PyObject*, const(char)*, Py_ssize_t) cwrite;
    /** Get the output object as a Python string (returns new reference). */
    PyObject* function(PyObject*) cgetvalue;
    /** Create a new output object */
    PyObject* function(int) NewOutput;
    /** Create an input object from a Python string
     (copies the Python string reference).
     */
    PyObject* function(PyObject*) NewInput;

    /** The Python types for cStringIO input and output objects.
     Note that you can do input on an output object.
     */
    PyTypeObject* InputType;
    /// ditto
    PyTypeObject* OutputType;
}

// D translations of C macros:
/// Availability: 2.*
int PycStringIO_InputCheck()(PyObject* o) {
    return Py_TYPE(o) == PycStringIO.InputType;
}
/// Availability: 2.*
int PycStringIO_OutputCheck()(PyObject* o) {
    return Py_TYPE(o) == PycStringIO.OutputType;
}


}
