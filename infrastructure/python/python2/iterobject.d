module python2.iterobject;

import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/iterobject.h:

__gshared PyTypeObject PySeqIter_Type;

// D translation of C macro:
int PySeqIter_Check()(PyObject* op) {
    return Py_TYPE(op) == &PySeqIter_Type;
}

PyObject* PySeqIter_New(PyObject*);

__gshared PyTypeObject PyCallIter_Type;

// D translation of C macro:
int PyCallIter_Check()(PyObject *op) {
    return op.ob_type == &PyCallIter_Type;
}

PyObject* PyCallIter_New(PyObject*, PyObject*);


