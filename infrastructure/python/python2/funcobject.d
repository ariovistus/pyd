module python2.funcobject;

import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/funcobject.h:

struct PyFunctionObject {
    mixin PyObject_HEAD;

    PyObject* func_code;
    PyObject* func_globals;
    PyObject* func_defaults;
    PyObject* func_closure;
    PyObject* func_doc;
    PyObject* func_name;
    PyObject* func_dict;
    PyObject* func_weakreflist;
    PyObject* func_module;
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
PyObject_BorrowedRef* PyFunction_GetClosure(PyObject*);
int PyFunction_SetClosure(PyObject*, PyObject*);

PyObject* PyFunction_GET_CODE()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_code;
}
PyObject* PyFunction_GET_GLOBALS()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_globals;
}
PyObject* PyFunction_GET_MODULE()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_module;
}
PyObject* PyFunction_GET_DEFAULTS()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_defaults;
}
PyObject* PyFunction_GET_CLOSURE()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_closure;
}

__gshared PyTypeObject PyClassMethod_Type;
__gshared PyTypeObject PyStaticMethod_Type;

PyObject* PyClassMethod_New(PyObject*);
PyObject* PyStaticMethod_New(PyObject*);


