import std.exception;
import std.typetuple;
import std.conv;
import std.traits;
import common;

extern(C) PyObject* test_pyd(PyObject* thing) {
    return Funs.long_to_python(3);
}

