/**
  Mirror _tupleobject.h

  Another generally useful object type is a tuple of object pointers.
  For Python, this is an immutable type.  C code can change the tuple items
  (but not their number), and even use tuples are general-purpose arrays of
  object references, but in general only brand new tuples should be mutated,
  not ones that might already have been exposed to Python code.
 */
module deimos.python.tupleobject;

import core.stdc.stdio;
import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/tupleobject.h:

/** ob_item contains space for 'ob_size' elements.
 * Items must normally not be NULL, except during construction when
 * the tuple is not yet visible outside the function that builds it.
 *
 * subclass of PyVarObject
 */
struct PyTupleObject {
    mixin PyObject_VAR_HEAD;

    // Will the D layout for a 1-PyObject* array be the same as the C layout?
    // I think the D array will be larger.
    PyObject*[1] _ob_item;
    /// _
    PyObject** ob_item()() {
        return _ob_item.ptr;
    }
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PyTuple_Type");
/// _
mixin(PyAPI_DATA!"PyTypeObject PyTupleIter_Type");

// D translation of C macro:
/// _
int PyTuple_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, &PyTuple_Type);
}
// D translation of C macro:
/// _
int PyTuple_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyTuple_Type;
}

/// _
PyObject* PyTuple_New(Py_ssize_t size);
/// _
Py_ssize_t PyTuple_Size(PyObject*);
/// _
PyObject_BorrowedRef* PyTuple_GetItem(PyObject*, Py_ssize_t);
/// _
int PyTuple_SetItem(PyObject*, Py_ssize_t, PyObject*);
/// _
PyObject* PyTuple_GetSlice(PyObject*, Py_ssize_t, Py_ssize_t);
/// _
int _PyTuple_Resize(PyObject**, Py_ssize_t);
/// _
PyObject* PyTuple_Pack(Py_ssize_t, ...);

// D translations of C macros:
// XXX: These do not work.
/// _
PyObject_BorrowedRef* PyTuple_GET_ITEM()(PyObject* op, Py_ssize_t i) {
    return (cast(PyTupleObject*) op).ob_item[i];
}
/// _
size_t PyTuple_GET_SIZE()(PyObject* op) {
    return (cast(PyTupleObject*) op).ob_size;
}
/// _
PyObject* PyTuple_SET_ITEM()(PyObject* op, Py_ssize_t i, PyObject* v) {
    PyTupleObject* opAsTuple = cast(PyTupleObject*) op;
    opAsTuple.ob_item[i] = v;
    return v;
}

version(Python_2_6_Or_Later){
    /// Availability: >= 2.6
    int PyTuple_ClearFreeList();
}
version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    void _PyTuple_DebugMallocStats(FILE* out_);
}
