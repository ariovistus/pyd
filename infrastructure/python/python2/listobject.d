module python2.listobject;

import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/listobject.h:

struct PyListObject {
    mixin PyObject_VAR_HEAD;

    PyObject** ob_item;
    Py_ssize_t allocated;
}

__gshared PyTypeObject PyList_Type;

// D translation of C macro:
int PyList_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, &PyList_Type);
}
// D translation of C macro:
int PyList_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyList_Type;
}

PyObject* PyList_New(Py_ssize_t size);
Py_ssize_t PyList_Size(PyObject*);

PyObject_BorrowedRef* PyList_GetItem(PyObject*, Py_ssize_t);
int PyList_SetItem(PyObject*, Py_ssize_t, PyObject*);
int PyList_Insert(PyObject*, Py_ssize_t, PyObject*);
int PyList_Append(PyObject*, PyObject*);
PyObject* PyList_GetSlice(PyObject*, Py_ssize_t, Py_ssize_t);
int PyList_SetSlice(PyObject*, Py_ssize_t, Py_ssize_t, PyObject*);
int PyList_Sort(PyObject*);
int PyList_Reverse(PyObject*);
PyObject* PyList_AsTuple(PyObject*);

// D translations of C macros:
PyObject_BorrowedRef* PyList_GET_ITEM()(PyObject* op, Py_ssize_t i) {
    return (cast(PyListObject*) op).ob_item[i];
}
void PyList_SET_ITEM()(PyObject* op, Py_ssize_t i, PyObject* v) {
    (cast(PyListObject*)op).ob_item[i] = v;
}
size_t PyList_GET_SIZE()(PyObject* op) {
    return (cast(PyListObject*) op).ob_size;
}


