module python2.floatobject;

import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/floatobject.h:

struct PyFloatObject {
    mixin PyObject_HEAD;

    double ob_fval;
}

__gshared PyTypeObject PyFloat_Type;

// D translation of C macro:
int PyFloat_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, &PyFloat_Type);
}
// D translation of C macro:
int PyFloat_CheckExact()(PyObject *op) {
    return Py_TYPE(op) == &PyFloat_Type;
}

version(Python_2_6_Or_Later){
    double PyFloat_GetMax();
    double PyFloat_GetMin();
    PyObject* PyFloat_GetInfo();
}

PyObject* PyFloat_FromString(PyObject*, char** junk);
PyObject* PyFloat_FromDouble(double);

double PyFloat_AsDouble(PyObject*);
void PyFloat_AsReprString(char*, PyFloatObject* v);
void PyFloat_AsString(char*, PyFloatObject* v);

version(Python_2_6_Or_Later){
    // _PyFloat_Digits ??
    // _PyFloat_DigitsInit ??
    /* free list api */
    int PyFloat_ClearFreeList();
    // _PyFloat_FormatAdvanced ??
}

