/**
  Mirror _objimpl.h
  */
module deimos.python.objimpl;

import deimos.python.pyport;
import deimos.python.object;

// Python-header-file: Include/objimpl.h:
extern(C):

/// _
void* PyObject_Malloc(size_t);

version(Python_3_5_Or_Later) {
    /// _
    void* PyObject_Calloc(size_t, size_t);
}
/// _
void* PyObject_Realloc(void*, size_t);
/// _
void PyObject_Free(void*);

 /**
   Don't allocate memory.  Instead of a 'type' parameter, take a pointer to a
   new object (allocated by an arbitrary allocator), and initialize its object
   header fields.
   */
PyObject_BorrowedRef* PyObject_Init(PyObject*, PyTypeObject*);
/// ditto
Borrowed!PyVarObject* PyObject_InitVar(PyVarObject*,
        PyTypeObject*, Py_ssize_t);
/// _
PyObject* _PyObject_New(PyTypeObject*);
/// _
PyVarObject* _PyObject_NewVar(PyTypeObject*, Py_ssize_t);
 /**
   Allocates memory for a new object of the given
   type, and initializes part of it.  'type' must be the C structure type used
   to represent the object, and 'typeobj' the address of the corresponding
   type object.  Reference count and type pointer are filled in; the rest of
   the bytes of the object are *undefined*!  The resulting expression type is
   'type *'.  The size of the object is determined by the tp_basicsize field
   of the type object.
   */
type* PyObject_New(type)(PyTypeObject* o) {
    return cast(type*)_PyObject_New(o);
}
/**
  PyObject_NewVar(type, typeobj, n) is similar but allocates a variable-size
   object with room for n items.  In addition to the refcount and type pointer
   fields, this also fills in the ob_size field.
   */
type* PyObject_NewVar(type)(PyTypeObject* o, Py_ssize_t n) {
    return cast(type*)_PyObject_NewVar(o, n);
}


/** C equivalent of gc.collect(). */
C_long PyGC_Collect();

// D translations of C macros:
/** Test if a type has a GC head */
int PyType_IS_GC()(PyTypeObject* t) {
    return PyType_HasFeature(t, Py_TPFLAGS_HAVE_GC);
}
/** Test if an object has a GC head */
int PyObject_IS_GC()(PyObject* o) {
    return PyType_IS_GC(o.ob_type)
        && (o.ob_type.tp_is_gc == null || o.ob_type.tp_is_gc(o));
}
/// _
PyVarObject* _PyObject_GC_Resize(PyVarObject *, Py_ssize_t);
/// _
type* PyObject_GC_Resize(type) (PyVarObject *op, Py_ssize_t n) {
    return cast(type*)_PyObject_GC_Resize(op, n);
}

/** GC information is stored BEFORE the object structure. */
union PyGC_Head {
    /// _
    struct _gc {
        /// _
        PyGC_Head *gc_next;
        /// _
        PyGC_Head *gc_prev;
        /// _
        Py_ssize_t gc_refs;
    }
    /// _
    _gc gc;
    /// _
    real dummy;
}

// Numerous macro definitions that appear in objimpl.h at this point are not
// document.  They appear to be for internal use, so they're omitted here.

/// _
PyObject* _PyObject_GC_Malloc(size_t);
version(Python_3_5_Or_Later) {
    /// _
    PyObject* _PyObject_GC_Calloc(size_t);
}
/// _
PyObject* _PyObject_GC_New(PyTypeObject*);
/// _
PyVarObject *_PyObject_GC_NewVar(PyTypeObject*, Py_ssize_t);
/// _
void PyObject_GC_Track(void*);
/// _
void PyObject_GC_UnTrack(void*);
/// _
void PyObject_GC_Del(void*);

/// _
type* PyObject_GC_New(type) (PyTypeObject* o) {
    return cast(type*)_PyObject_GC_New(o);
}
/// _
type* PyObject_GC_NewVar(type) (PyTypeObject* o, Py_ssize_t n) {
    return cast(type*)_PyObject_GC_NewVar(o, n);
}

/** Test if a type supports weak references */
auto PyType_SUPPORTS_WEAKREFS()(PyObject* t) {
    version(Python_3_0_Or_Later) {
        return (t.tp_weaklistoffset > 0);
    }else{
        return (PyType_HasFeature(t, Py_TPFLAGS_HAVE_WEAKREFS)
                && (t.tp_weaklistoffset > 0));
    }
}

/// _
auto PyObject_GET_WEAKREFS_LISTPTR(T)(T o) {
    return cast(PyObject**) ((cast(char *) o) + Py_TYPE(o).tp_weaklistoffset);
}
