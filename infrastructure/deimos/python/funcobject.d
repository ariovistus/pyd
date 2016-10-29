/**
  Mirror _funcobject.h

Function object interface

 * Function objects and code objects should not be confused with each other:
 *
 * Function objects are created by the execution of the 'def' statement.
 * They reference a code object in their func_code attribute, which is a
 * purely syntactic object, i.e. nothing more than a compiled version of some
 * source code lines.  There is one code object per source code "fragment",
 * but each code object can be referenced by zero or many function objects
 * depending only on how many times the 'def' statement in the source was
 * executed so far.
 */
module deimos.python.funcobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/funcobject.h:

    /** subclass of PyObject
     *
     *  Invariant:
     *     func_closure contains the bindings for func_code->co_freevars, so
     *     PyTuple_Size(func_closure) == PyCode_GetNumFree(func_code)
     *     (func_closure may be NULL if PyCode_GetNumFree(func_code) == 0).
     */
struct PyFunctionObject {
    mixin PyObject_HEAD;
    /** A code object */
    PyObject* func_code;
    /** A dictionary (other mappings won't do) */
    PyObject* func_globals;
    /** NULL or a tuple */
    PyObject* func_defaults;
    version(Python_3_0_Or_Later) {
        /** NULL or a dict */
        /// Availability: 3.*
        PyObject* func_kwdefaults;
    }
    /** NULL or a tuple of cell objects */
    PyObject* func_closure;
    /** The __doc__ attribute, can be anything */
    PyObject* func_doc;
    /** The __name__ attribute, a string object */
    PyObject* func_name;
    /** The __dict__ attribute, a dict or NULL */
    PyObject* func_dict;
    /** List of weak references */
    PyObject* func_weakreflist;
    /** The __module__ attribute, can be anything */
    PyObject* func_module;
    version(Python_3_0_Or_Later) {
        /** Annotations, a dict or NULL */
        /// Availability: 3.*
        PyObject* func_annotations;
    }
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PyFunction_Type");

// D translation of C macro:
/// _
int PyFunction_Check()(PyObject* op) {
    return op.ob_type == &PyFunction_Type;
}

/// _
PyObject* PyFunction_New(PyObject*, PyObject*);
/// _
PyObject_BorrowedRef* PyFunction_GetCode(PyObject*);
/// _
PyObject_BorrowedRef* PyFunction_GetGlobals(PyObject*);
/// _
PyObject_BorrowedRef* PyFunction_GetModule(PyObject*);
/// _
PyObject_BorrowedRef* PyFunction_GetDefaults(PyObject*);
/// _
int PyFunction_SetDefaults(PyObject*, PyObject*);
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    Borrowed!PyObject* PyFunction_GetKwDefaults(PyObject*);
    /// Availability: 3.*
    int PyFunction_SetKwDefaults(PyObject*, PyObject*);
}
/// _
PyObject_BorrowedRef* PyFunction_GetClosure(PyObject*);
/// _
int PyFunction_SetClosure(PyObject*, PyObject*);
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    Borrowed!PyObject* PyFunction_GetAnnotations(PyObject*);
    /// Availability: 3.*
    int PyFunction_SetAnnotations(PyObject*, PyObject*);
}

/** Macros for direct access to these values. Type checks are *not*
   done, so use with care. */
Borrowed!PyObject* PyFunction_GET_CODE()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_code;
}
/// ditto
Borrowed!PyObject* PyFunction_GET_GLOBALS()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_globals;
}
/// ditto
Borrowed!PyObject* PyFunction_GET_MODULE()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_module;
}
/// ditto
Borrowed!PyObject* PyFunction_GET_DEFAULTS()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_defaults;
}
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    Borrowed!PyObject* PyFunction_GET_KW_DEFAULTS()(PyObject* func) {
        return (cast(PyFunctionObject*)func).func_kwdefaults;
    }
}
/// _
Borrowed!PyObject* PyFunction_GET_CLOSURE()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_closure;
}
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    Borrowed!PyObject* PyFunction_GET_ANNOTATIONS()(PyObject* func) {
        return (cast(PyFunctionObject*)func).func_annotations;
    }
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PyClassMethod_Type");
/// _
mixin(PyAPI_DATA!"PyTypeObject PyStaticMethod_Type");

/// _
PyObject* PyClassMethod_New(PyObject*);
/// _
PyObject* PyStaticMethod_New(PyObject*);


