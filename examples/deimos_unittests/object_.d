import deimos.python.object;

unittest {
    // breaks linking?
    Py_XINCREF(Py_None());
    // breaks linking?
    Py_XDECREF(cast(PyObject*) null);
}


void main() {}
