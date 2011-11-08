// A module written to the raw Python/C API.
module rawexample;

import python;
import std.stdio;

static PyTypeObject Base_type;
static PyTypeObject Derived_type;

struct Base_object {
    mixin PyObject_HEAD;
}

struct Derived_object {
    mixin PyObject_HEAD;
}

extern(C)
PyObject* Base_foo(PyObject* self, PyObject* args) {
    writefln("Base.foo");
    Py_INCREF(Py_None);
    return Py_None;
}

extern(C)
PyObject* Base_bar(PyObject* self, PyObject* args) {
    writefln("Base.bar");
    Py_INCREF(Py_None);
    return Py_None;
}

PyMethodDef[] Base_methods = [
    {"foo", &Base_foo, METH_VARARGS, ""},
    {"bar", &Base_bar, METH_VARARGS, ""},
    {null, null, 0, null}
];

extern(C)
PyObject* Derived_bar(PyObject* self, PyObject* args) {
    writefln("Derived.bar");
    Py_INCREF(Py_None);
    return Py_None;
}

PyMethodDef[] Derived_methods = [
    {"bar", &Derived_bar, METH_VARARGS, ""},
    {null, null, 0, null}
];

extern(C)
PyObject* hello(PyObject* self, PyObject* args) {
    writefln("Hello, world!");
    Py_INCREF(Py_None);
    return Py_None;
}

PyMethodDef[] rawexample_methods = [
    {"hello", &hello, METH_VARARGS, ""},
    {null, null, 0, null}
];

extern(C)
export void initrawexample() {
    PyObject* m = Py_InitModule("rawexample", rawexample_methods.ptr);

    Base_type.ob_type = PyType_Type_p;
    Base_type.tp_basicsize = Base_object.sizeof;
    Base_type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
    Base_type.tp_methods = Base_methods.ptr;
    Base_type.tp_name = "rawexample.Base";
    Base_type.tp_new = &PyType_GenericNew;
    PyType_Ready(&Base_type);
    Py_INCREF(cast(PyObject*)&Base_type);
    PyModule_AddObject(m, "Base", cast(PyObject*)&Base_type);

    Derived_type.ob_type = PyType_Type_p;
    Derived_type.tp_basicsize = Derived_object.sizeof;
    Derived_type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
    Derived_type.tp_methods = Derived_methods.ptr;
    Derived_type.tp_name = "rawexample.Derived";
    Derived_type.tp_new = &PyType_GenericNew;
    Derived_type.tp_base = &Base_type;
    PyType_Ready(&Derived_type);
    Py_INCREF(cast(PyObject*)&Derived_type);
    PyModule_AddObject(m, "Derived", cast(PyObject*)&Derived_type);
}

