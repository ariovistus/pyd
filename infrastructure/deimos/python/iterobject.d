/**
  Mirror _iterobject.h

  Iterators (the basic kind, over a sequence)
  */
module deimos.python.iterobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/iterobject.h:

/// _
mixin(PyAPI_DATA!"PyTypeObject PySeqIter_Type");

// D translation of C macro:
/// _
int PySeqIter_Check()(PyObject* op) {
    return Py_TYPE(op) is &PySeqIter_Type;
}

/// _
PyObject* PySeqIter_New(PyObject*);

/// _
mixin(PyAPI_DATA!"PyTypeObject PyCallIter_Type");
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    mixin(PyAPI_DATA!"PyTypeObject PyCmpWrapper_Type");
}

// D translation of C macro:
/// _
int PyCallIter_Check()(PyObject *op) {
    return op.ob_type is &PyCallIter_Type;
}

/// _
PyObject* PyCallIter_New(PyObject*, PyObject*);


