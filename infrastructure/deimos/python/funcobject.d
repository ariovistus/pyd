module deimos.python.funcobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/funcobject.h:

struct PyFunctionObject {
    mixin PyObject_HEAD;

    PyObject* func_code;
    PyObject* func_globals;
    PyObject* func_defaults;
    version(Python_3_0_Or_Later) {
        PyObject* func_kwdefaults;	/* NULL or a dict */
    }
    PyObject* func_closure;
    PyObject* func_doc;
    PyObject* func_name;
    PyObject* func_dict;
    PyObject* func_weakreflist;
    PyObject* func_module;
    version(Python_3_0_Or_Later) {
        PyObject* func_annotations;	/* Annotations, a dict or NULL */
    }
}

__gshared PyTypeObject PyFunction_Type;

// D translation of C macro:
int PyFunction_Check()(PyObject* op) {
    return op.ob_type == &PyFunction_Type;
}

PyObject* PyFunction_New(PyObject*, PyObject*);
PyObject_BorrowedRef* PyFunction_GetCode(PyObject*);
PyObject_BorrowedRef* PyFunction_GetGlobals(PyObject*);
PyObject_BorrowedRef* PyFunction_GetModule(PyObject*);
PyObject_BorrowedRef* PyFunction_GetDefaults(PyObject*);
int PyFunction_SetDefaults(PyObject*, PyObject*);
version(Python_3_0_Or_Later) {
    Borrowed!PyObject* PyFunction_GetKwDefaults(PyObject*);
    int PyFunction_SetKwDefaults(PyObject*, PyObject*);
}
PyObject_BorrowedRef* PyFunction_GetClosure(PyObject*);
int PyFunction_SetClosure(PyObject*, PyObject*);
version(Python_3_0_Or_Later) {
    Borrowed!PyObject* PyFunction_GetAnnotations(PyObject*);
    int PyFunction_SetAnnotations(PyObject*, PyObject*);
}

Borrowed!PyObject* PyFunction_GET_CODE()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_code;
}
Borrowed!PyObject* PyFunction_GET_GLOBALS()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_globals;
}
Borrowed!PyObject* PyFunction_GET_MODULE()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_module;
}
Borrowed!PyObject* PyFunction_GET_DEFAULTS()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_defaults;
}
version(Python_3_0_Or_Later) {
    Borrowed!PyObject* PyFunction_GET_KW_DEFAULTS()(PyObject* func) { 
        return (cast(PyFunctionObject*)func).func_kwdefaults;
    }
}
Borrowed!PyObject* PyFunction_GET_CLOSURE()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_closure;
}
version(Python_3_0_Or_Later) {
    Borrowed!PyObject* PyFunction_GET_ANNOTATIONS()(PyObject* func) {
        return (cast(PyFunctionObject*)func).func_annotations;
    }
}

__gshared PyTypeObject PyClassMethod_Type;
__gshared PyTypeObject PyStaticMethod_Type;

PyObject* PyClassMethod_New(PyObject*);
PyObject* PyStaticMethod_New(PyObject*);


