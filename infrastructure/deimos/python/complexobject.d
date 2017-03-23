/**
  Mirror _complexobject.h
  */
module deimos.python.complexobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.unicodeobject;

extern(C):
// Python-header-file: Include/complexobject.h:

/// _
struct Py_complex {
    /// _
    double real_;
    /// _
    double imag;
}

/// _
Py_complex _Py_c_sum(Py_complex, Py_complex);
/// _
Py_complex _Py_c_diff(Py_complex, Py_complex);
/// _
Py_complex _Py_c_neg(Py_complex);
/// _
Py_complex _Py_c_prod(Py_complex, Py_complex);
/// _
Py_complex _Py_c_quot(Py_complex, Py_complex);
/// _
Py_complex _Py_c_pow(Py_complex, Py_complex);
version(Python_2_6_Or_Later){
    /// Availability: >= 2.6
    double _Py_c_abs(Py_complex);
}

/**
PyComplexObject represents a complex number with double-precision
real and imaginary parts.

subclass of PyObject.
*/
struct PyComplexObject {
    mixin PyObject_HEAD;

    /// _
    Py_complex cval;
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PyComplex_Type");

// D translation of C macro:
/// _
int PyComplex_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, &PyComplex_Type);
}
// D translation of C macro:
/// _
int PyComplex_CheckExact()(PyObject *op) {
    return Py_TYPE(op) == &PyComplex_Type;
}

/// _
PyObject* PyComplex_FromCComplex(Py_complex);
/// _
PyObject* PyComplex_FromDoubles(double real_, double imag);
/// _
double PyComplex_RealAsDouble(PyObject* op);
/// _
double PyComplex_ImagAsDouble(PyObject* op);
/// _
Py_complex PyComplex_AsCComplex(PyObject* op);

version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    PyObject* _PyComplex_FormatAdvanced(
            PyObject* obj,
            Py_UNICODE* format_spec,
            Py_ssize_t format_spec_len);
}else version(Python_2_7_Or_Later) {
    /** Format the object based on the format_spec, as defined in PEP 3101
   (Advanced String Formatting). */
    /// Availability: >= 2.6
    PyObject* _PyComplex_FormatAdvanced(
            PyObject* obj,
            char* format_spec,
            Py_ssize_t format_spec_len);
}


