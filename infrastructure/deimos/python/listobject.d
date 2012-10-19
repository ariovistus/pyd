/**
  Mirror _listobject.h

Another generally useful object type is an list of object pointers.
This is a mutable type: the list items can be changed, and items can be
added or removed.  Out-of-range indices or non-list objects are ignored.
  */
module deimos.python.listobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/listobject.h:

/** ob_item contains space for 'allocated' elements.  The number
 * currently in use is ob_size.
 * Invariants:
 *     0 <= ob_size <= allocated
 *     len(list) == ob_size
 *     ob_item == NULL implies ob_size == allocated == 0
 * list.sort() temporarily sets allocated to -1 to detect mutations.
 *
 * Items must normally not be NULL, except during construction when
 * the list is not yet visible outside the function that builds it.
 *
 * subclass of PyObject.
 */
struct PyListObject {
    mixin PyObject_VAR_HEAD;

    /** Vector of pointers to list elements.  list[0] is ob_item[0], etc. */
    PyObject** ob_item;
    /// _
    Py_ssize_t allocated;
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PyList_Type");
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    mixin(PyAPI_DATA!"PyTypeObject PyListIter_Type");
    /// Availability: 3.*
    mixin(PyAPI_DATA!"PyTypeObject PyListRevIter_Type");
    /// Availability: 3.*
    mixin(PyAPI_DATA!"PyTypeObject PySortWrapper_Type");
}

// D translation of C macro:
/// _
int PyList_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, &PyList_Type);
}
// D translation of C macro:
/// _
int PyList_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyList_Type;
}

/// _
PyObject* PyList_New(Py_ssize_t size);
/// _
Py_ssize_t PyList_Size(PyObject*);

/** WARNING: PyList_SetItem does not increment the new item's reference
count, but does decrement the reference count of the item it replaces,
if not nil.  It does *decrement* the reference count if it is *not*
inserted in the list.  Similarly, PyList_GetItem does not increment the
returned item's reference count.
*/
PyObject_BorrowedRef* PyList_GetItem(PyObject*, Py_ssize_t);
/// ditto
int PyList_SetItem(PyObject*, Py_ssize_t, PyObject*);
/// _
int PyList_Insert(PyObject*, Py_ssize_t, PyObject*);
/// _
int PyList_Append(PyObject*, PyObject*);
/// _
PyObject* PyList_GetSlice(PyObject*, Py_ssize_t, Py_ssize_t);
/// _
int PyList_SetSlice(PyObject*, Py_ssize_t, Py_ssize_t, PyObject*);
/// _
int PyList_Sort(PyObject*);
/// _
int PyList_Reverse(PyObject*);
/// _
PyObject* PyList_AsTuple(PyObject*);

// D translations of C macros:
/// _
PyObject_BorrowedRef* PyList_GET_ITEM()(PyObject* op, Py_ssize_t i) {
    return (cast(PyListObject*) op).ob_item[i];
}
/// _
void PyList_SET_ITEM()(PyObject* op, Py_ssize_t i, PyObject* v) {
    (cast(PyListObject*)op).ob_item[i] = v;
}
/// _
Py_ssize_t PyList_GET_SIZE()(PyObject* op) {
    return (cast(PyListObject*) op).ob_size;
}


