/**
  Mirror _weakrefobject.h

Weak references objects for Python.
  */
module deimos.python.weakrefobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/weakrefobject.h:

/** PyWeakReference is the base struct for the Python ReferenceType, ProxyType,
 * and CallableProxyType.
 *
 * subclass of PyObject
 */
struct PyWeakReference {
    mixin PyObject_HEAD;

    /**The object to which this is a weak reference, or Py_None if none.
     * Note that this is a stealth reference:  wr_object's refcount is
     * not incremented to reflect this pointer.
     */
    PyObject* wr_object;
    /** A callable to invoke when wr_object dies, or NULL if none. */
    PyObject* wr_callback;
    /** A cache for wr_object's hash code.  As usual for hashes, this is -1
     * if the hash code isn't known yet.
     */
    version(Python_3_2_Or_Later) {
        Py_hash_t hash;
    }else{
        C_long hash;
    }
    /** If wr_object is weakly referenced, wr_object has a doubly-linked NULL-
     * terminated list of weak references to it.  These are the list pointers.
     * If wr_object goes away, wr_object is set to Py_None, and these pointers
     * have no meaning then.
     */
    PyWeakReference* wr_prev;
    /// ditto
    PyWeakReference* wr_next;
}

/// _
mixin(PyAPI_DATA!"PyTypeObject _PyWeakref_RefType");
/// _
mixin(PyAPI_DATA!"PyTypeObject _PyWeakref_ProxyType");
/// _
mixin(PyAPI_DATA!"PyTypeObject _PyWeakref_CallableProxyType");

// D translations of C macros:
/// _
int PyWeakref_CheckRef()(PyObject* op) {
    return PyObject_TypeCheck(op, &_PyWeakref_RefType);
}
/// _
int PyWeakref_CheckRefExact()(PyObject* op) {
    return Py_TYPE(op) == &_PyWeakref_RefType;
}
/// _
int PyWeakref_CheckProxy()(PyObject* op) {
    return Py_TYPE(op) == &_PyWeakref_ProxyType
        || Py_TYPE(op) == &_PyWeakref_CallableProxyType;
}
/** This macro calls PyWeakref_CheckRef() last since that can involve a
   function call; this makes it more likely that the function call
   will be avoided. */
int PyWeakref_Check()(PyObject* op) {
    return PyWeakref_CheckRef(op) || PyWeakref_CheckProxy(op);
}

/// _
PyObject* PyWeakref_NewRef(PyObject* ob, PyObject* callback);
/// _
PyObject* PyWeakref_NewProxy(PyObject* ob, PyObject* callback);
/// _
PyObject_BorrowedRef* PyWeakref_GetObject(PyObject* _ref);

version(Python_2_5_Or_Later){
    /// _
    Py_ssize_t _PyWeakref_GetWeakrefCount(PyWeakReference* head);
}else{
    /// _
    C_long _PyWeakref_GetWeakrefCount(PyWeakReference *head);
}
/// _
void _PyWeakref_ClearRef(PyWeakReference *self);

/// _
PyObject_BorrowedRef* PyWeakref_GET_OBJECT()(PyObject* _ref) {
    return (cast(PyWeakReference *) _ref).wr_object;
}

