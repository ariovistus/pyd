module python2.tupleobject;

import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/tupleobject.h:

struct PyTupleObject {
    mixin PyObject_VAR_HEAD;

    // DSR:XXX:LAYOUT:
    // Will the D layout for a 1-PyObject* array be the same as the C layout?
    // I think the D array will be larger.
    PyObject* _ob_item[1];
    PyObject** ob_item()() {
        return _ob_item.ptr;
    }
}

__gshared PyTypeObject PyTuple_Type;

// D translation of C macro:
int PyTuple_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, &PyTuple_Type);
}
// D translation of C macro:
int PyTuple_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyTuple_Type;
}

PyObject* PyTuple_New(Py_ssize_t size);
Py_ssize_t PyTuple_Size(PyObject*);
PyObject_BorrowedRef* PyTuple_GetItem(PyObject*, Py_ssize_t);
int PyTuple_SetItem(PyObject*, Py_ssize_t, PyObject*);
PyObject* PyTuple_GetSlice(PyObject*, Py_ssize_t, Py_ssize_t);
int _PyTuple_Resize(PyObject**, Py_ssize_t);
PyObject* PyTuple_Pack(Py_ssize_t, ...);

// D translations of C macros:
// XXX: These do not work.
PyObject_BorrowedRef* PyTuple_GET_ITEM()(PyObject* op, Py_ssize_t i) {
    return (cast(PyTupleObject *) op).ob_item[i];
}
size_t PyTuple_GET_SIZE()(PyObject* op) {
    return (cast(PyTupleObject *) op).ob_size;
}
PyObject* PyTuple_SET_ITEM()(PyObject* op, Py_ssize_t i, PyObject* v) {
    PyTupleObject *opAsTuple = cast(PyTupleObject *) op;
    opAsTuple.ob_item[i] = v;
    return v;
}

version(Python_2_6_Or_Later){
    int PyTuple_ClearFreeList();
}

