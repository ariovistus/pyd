module deimos.python.objimpl;

import deimos.python.pyport;
import deimos.python.object;

// Python-header-file: Include/objimpl.h:
extern(C):

void* PyObject_Malloc(size_t);
void* PyObject_Realloc(void*, size_t);
void PyObject_Free(void*);

PyObject_BorrowedRef* PyObject_Init(PyObject*, PyTypeObject*);

Borrowed!PyVarObject* PyObject_InitVar(PyVarObject*,
        PyTypeObject*, Py_ssize_t);
PyObject* _PyObject_New(PyTypeObject*);
PyVarObject* _PyObject_NewVar(PyTypeObject*, Py_ssize_t);
type* PyObject_New(type)(PyTypeObject* o) {
    return cast(type*)_PyObject_New(o);
}
type* PyObject_NewVar(type)(PyTypeObject* o, Py_ssize_t n) {
    return cast(type*)_PyObject_NewVar(o, n);
}


C_long PyGC_Collect();

// D translations of C macros:
int PyType_IS_GC()(PyTypeObject* t) {
    return PyType_HasFeature(t, Py_TPFLAGS_HAVE_GC);
}
int PyObject_IS_GC()(PyObject* o) {
    return PyType_IS_GC(o.ob_type)
        && (o.ob_type.tp_is_gc == null || o.ob_type.tp_is_gc(o));
}
PyVarObject* _PyObject_GC_Resize(PyVarObject *, Py_ssize_t);
type* PyObject_GC_Resize(type) (PyVarObject *op, Py_ssize_t n) {
    return cast(type*)_PyObject_GC_Resize(op, n);
}

union PyGC_Head {
    struct gc {
        PyGC_Head *gc_next;
        PyGC_Head *gc_prev;
        Py_ssize_t gc_refs;
    }
    real dummy; 
}

// Numerous macro definitions that appear in objimpl.h at this point are not
// document.  They appear to be for internal use, so they're omitted here.

PyObject* _PyObject_GC_Malloc(size_t);
PyObject* _PyObject_GC_New(PyTypeObject*);
PyVarObject *_PyObject_GC_NewVar(PyTypeObject*, Py_ssize_t);
void PyObject_GC_Track(void*);
void PyObject_GC_UnTrack(void*);
void PyObject_GC_Del(void*);

type* PyObject_GC_New(type) (PyTypeObject* o) {
    return cast(type*)_PyObject_GC_New(o);
}
type* PyObject_GC_NewVar(type) (PyTypeObject* o, Py_ssize_t n) {
    return cast(type*)_PyObject_GC_NewVar(o, n);
}

auto PyType_SUPPORTS_WEAKREFS()(PyObject* t) {
    version(Python_3_0_Or_Later) {
        return (t.tp_weaklistoffset > 0);
    }else{
        return (PyType_HasFeature(t, Py_TPFLAGS_HAVE_WEAKREFS) 
                && (t.tp_weaklistoffset > 0));
    }
}

auto PyObject_GET_WEAKREFS_LISTPTR(T)(T o) {
    return cast(PyObject**) ((cast(char *) o) + Py_TYPE(o).tp_weaklistoffset);
}
