module deimos.python.floatobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.pythonrun;
import std.c.stdio;

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

version(Python_3_0_Or_Later) {
    PyObject* PyFloat_FromString(PyObject*);
}else{
    PyObject* PyFloat_FromString(PyObject*, char** junk);
}
PyObject* PyFloat_FromDouble(double);

double PyFloat_AsDouble(PyObject*);
version(Python_3_0_Or_Later) {
}else{
    void PyFloat_AsReprString(char*, PyFloatObject* v);
    void PyFloat_AsString(char*, PyFloatObject* v);
}

int _PyFloat_Pack4(double x, ubyte* p, int le);
int _PyFloat_Pack8(double x, ubyte* p, int le);

version(Python_3_0_Or_Later) {
    int _PyFloat_Repr(double x, char* p, size_t len);
}

version(Python_2_6_Or_Later){
    int _PyFloat_Digits(char* buf, double v, int* signum);
    void _PyFloat_DigitsInit();
    /* free list api */
    int PyFloat_ClearFreeList();
}

version(Python_2_7_Or_Later) {
    void _PyFloat_DebugMallocStats(FILE* out_);
}
version(Python_3_0_Or_Later) {
    PyObject* _PyFloat_FormatAdvanced(PyObject* obj,
            Py_UNICODE* format_spec,
            Py_ssize_t format_spec_len);
}else{
    version(Python_2_7_Or_Later) {
        PyObject* _Py_double_round(double x, int ndigits);
    }
    version(Python_2_6_Or_Later) {
        PyObject* _PyFloat_FormatAdvanced(PyObject* obj,
                char* format_spec,
                Py_ssize_t format_spec_len);
    }
}
