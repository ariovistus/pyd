module python2.weakrefobject;

import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/weakrefobject.h:

struct PyWeakReference {
    mixin PyObject_HEAD;

    PyObject* wr_object;
    PyObject* wr_callback;
    C_long hash;
    PyWeakReference* wr_prev;
    PyWeakReference* wr_next;
}

__gshared PyTypeObject _PyWeakref_RefType;
__gshared PyTypeObject _PyWeakref_ProxyType;
__gshared PyTypeObject _PyWeakref_CallableProxyType;

// D translations of C macros:
int PyWeakref_CheckRef()(PyObject* op) {
    return PyObject_TypeCheck(op, &_PyWeakref_RefType);
}
int PyWeakref_CheckRefExact()(PyObject* op) {
    return Py_TYPE(op) == &_PyWeakref_RefType;
}
int PyWeakref_CheckProxy()(PyObject* op) {
    return Py_TYPE(op) == &_PyWeakref_ProxyType
        || Py_TYPE(op) == &_PyWeakref_CallableProxyType;
}
int PyWeakref_Check()(PyObject* op) {
    return PyWeakref_CheckRef(op) || PyWeakref_CheckProxy(op);
}

PyObject* PyWeakref_NewRef(PyObject* ob, PyObject* callback);
PyObject* PyWeakref_NewProxy(PyObject* ob, PyObject* callback);
PyObject_BorrowedRef* PyWeakref_GetObject(PyObject* _ref);

version(Python_2_5_Or_Later){
    Py_ssize_t _PyWeakref_GetWeakrefCount(PyWeakReference* head);
}else{
    C_long _PyWeakref_GetWeakrefCount(PyWeakReference *head);
}
void _PyWeakref_ClearRef(PyWeakReference *self);

PyObject_BorrowedRef* PyWeakref_GET_OBJECT()(PyObject* _ref) {
    return (cast(PyWeakReference *) _ref).wr_object;
}

