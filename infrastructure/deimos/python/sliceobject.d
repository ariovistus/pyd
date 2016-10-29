/**
  Mirror _sliceobject.h

  Slice object interface
  */
module deimos.python.sliceobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/sliceobject.h:

mixin(PyAPI_DATA!"PyObject _Py_EllipsisObject");

/** The unique ellipsis object "..." */
@property PyObject* Py_Ellipsis()() {
    return &_Py_EllipsisObject;
}

/**
A slice object containing start, stop, and step data members (the
names are from range).  After much talk with Guido, it was decided to
let these be any arbitrary python type.  Py_None stands for omitted values.

subclass of PyObject
*/
struct PySliceObject {
    mixin PyObject_HEAD;
    /** not NULL */
    PyObject* start;
    /// ditto
    PyObject* stop;
    /// ditto
    PyObject* step;
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PySlice_Type");

// D translation of C macro:
/// _
int PySlice_Check()(PyObject* op) {
    return Py_TYPE(op) == &PySlice_Type;
}

/// _
PyObject* PySlice_New(PyObject* start, PyObject* stop, PyObject* step);
// before python 3.2, r was typed as PySliceObject*, but bah humbug.
/// _
int PySlice_GetIndices(PyObject* r, Py_ssize_t length,
        Py_ssize_t* start, Py_ssize_t* stop, Py_ssize_t* step);
// before python 3.2, r was typed as PySliceObject*, but bah humbug.
/// _
int PySlice_GetIndicesEx(PyObject* r, Py_ssize_t length,
        Py_ssize_t* start, Py_ssize_t* stop,
        Py_ssize_t* step, Py_ssize_t* slicelength);


