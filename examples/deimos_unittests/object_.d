import std.string;

import std.stdio;
import deimos.python.Python;

shared static this() {
    Py_Initialize();
}

unittest {
    PyObject* type1 = PyObject_Type(PyObject_Type(PyDict_New()));
    PyObject* type2 = cast(PyObject*) &PyType_Type;
    // linker broken?
    assert(type1 == type2, format("problem: deimos' PyType_Type isn't pointing at python's PyType_Type (py:%x, d:%x)",type1, type2));
}

unittest {
    // breaks linking?
    Py_XINCREF(Py_None());
    // breaks linking?
    Py_XDECREF(cast(PyObject*) Py_None());
    // breaks linking?
    PyObject_TypeCheck(cast(PyObject*) Py_None(), &PyType_Type);
}


void main() {}
