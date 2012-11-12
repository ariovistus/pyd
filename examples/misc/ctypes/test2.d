import std.exception;
import std.typetuple;
import std.conv;
import std.traits;

import common;

PyObject* d_to_python(T)(T t) {
    static if(isIntegral!T) {
        static if(isUnsigned!T) {
            ulong arg = t;
            return Funs.ulong_to_python(arg);
        }else static if(isSigned!T) {
            long arg  = t;
            import std.stdio;
            writefln("Funs.long_to_python: %s", Funs.long_to_python);
            auto result = Funs.long_to_python(arg);
            writefln("long_to_python result: %s", result);
            return result;
        }
    }
}

extern(C) PyObject* test_long_to_d(PyObject* a) {
    return Funs.long_to_python(3);
}

extern(C) PyObject* test_pyd(PyObject* thing) {
    import std.stdio;
    writefln("Funs.get_item: %s", Funs.get_item);
    auto z = d_to_python(3);
    writefln("z: %s", z);
    return Funs.get_item(thing, z);
}

