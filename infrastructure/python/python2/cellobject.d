module python2.cellobject;

import python2.types;
import python2.object;

extern(C):

// Python-header-file: Include/cellobject.h:

struct PyCellObject {
    mixin PyObject_HEAD;

    PyObject *ob_ref;
}

__gshared PyTypeObject PyCell_Type;

// D translation of C macro:
int PyCell_Check()(PyObject *op) {
    return Py_TYPE(op) == &PyCell_Type;
}

PyObject* PyCell_New(PyObject*);
PyObject* PyCell_Get(PyObject*);
int PyCell_Set(PyObject*, PyObject*);

int PyCell_GET()(PyObject* op) {
    return (cast(PyCellObject*)op).ob_ref;
}
int PyCell_SET()(PyObject* op, PyObject* v) {
    (cast(PyCellObject*)op).ob_ref = v;
}

