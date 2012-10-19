/**
  Mirror _cellobject.h
  */
module deimos.python.cellobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):

/// subclass of PyObject.
struct PyCellObject {
    mixin PyObject_HEAD;
    /** Content of the cell or NULL when empty */
    PyObject* ob_ref;
}

///_
mixin(PyAPI_DATA!"PyTypeObject PyCell_Type");

// D translation of C macro:
///_
int PyCell_Check()(PyObject* op) {
    return Py_TYPE(op) == &PyCell_Type;
}

///_
PyObject* PyCell_New(PyObject*);
///_
PyObject* PyCell_Get(PyObject*);
///_
int PyCell_Set(PyObject*, PyObject*);
///_
int PyCell_GET()(PyObject* op) {
    return (cast(PyCellObject*)op).ob_ref;
}
///_
int PyCell_SET()(PyObject* op, PyObject* v) {
    (cast(PyCellObject*)op).ob_ref = v;
}

