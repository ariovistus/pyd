module deimos.python.iterobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/iterobject.h:

__gshared PyTypeObject PySeqIter_Type;

// D translation of C macro:
int PySeqIter_Check()(PyObject* op) {
    return Py_TYPE(op) is &PySeqIter_Type;
}

PyObject* PySeqIter_New(PyObject*);

__gshared PyTypeObject PyCallIter_Type;
version(Python_3_0_Or_Later) {
    __gshared PyTypeObject PyCmpWrapper_Type;
}

// D translation of C macro:
int PyCallIter_Check()(PyObject *op) {
    return op.ob_type is &PyCallIter_Type;
}

PyObject* PyCallIter_New(PyObject*, PyObject*);


