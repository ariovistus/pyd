import std.exception;
import std.typetuple;
import std.conv;
import std.traits;

import common;

extern(C) PyObject* test_pyd(PyObject* thing) {
    try{
        enforce(false);
    }catch(Throwable t) {
        Funs.raise(("D Exception:\n" ~ t.toString() ~ "\0").ptr);
    }
    return thing;
}

