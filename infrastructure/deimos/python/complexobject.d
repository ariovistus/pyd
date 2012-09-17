module deimos.python.complexobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/complexobject.h:

struct Py_complex {
    double real_; // real is the name of a D type, so must rename
    double imag;
}

Py_complex c_sum(Py_complex, Py_complex);
Py_complex c_diff(Py_complex, Py_complex);
Py_complex c_neg(Py_complex);
Py_complex c_prod(Py_complex, Py_complex);
Py_complex c_quot(Py_complex, Py_complex);
Py_complex c_pow(Py_complex, Py_complex);
version(Python_2_6_Or_Later){
    double c_abs(Py_complex);
}

struct PyComplexObject {
    mixin PyObject_HEAD;

    Py_complex cval;
}

__gshared PyTypeObject PyComplex_Type;

// D translation of C macro:
int PyComplex_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, &PyComplex_Type);
}
// D translation of C macro:
int PyComplex_CheckExact()(PyObject *op) {
    return Py_TYPE(op) == &PyComplex_Type;
}

PyObject* PyComplex_FromCComplex(Py_complex);
PyObject* PyComplex_FromDoubles(double real_, double imag);

double PyComplex_RealAsDouble(PyObject* op);
double PyComplex_ImagAsDouble(PyObject* op);
Py_complex PyComplex_AsCComplex(PyObject* op);

version(Python_3_0_Or_Later) {
    PyObject* _PyComplex_FormatAdvanced(
            PyObject* obj,
            Py_UNICODE* format_spec,
            Py_ssize_t format_spec_len);
}else version(Python_2_7_Or_Later) {
    PyObject* _PyComplex_FormatAdvanced(
            PyObject* obj,
            char* format_spec,
            Py_ssize_t format_spec_len);
}


