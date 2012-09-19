import deimos.python.object;

unittest {
    // breaks linking?
    Py_XINCREF(Py_None());
    // breaks linking?
    Py_XDECREF(cast(PyObject*) null);
    // breaks linking?
    PyObject_TypeCheck(cast(PyObject*) Py_None(), &PyType_Type);
    
}


void main() {}
