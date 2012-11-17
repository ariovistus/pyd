import std.exception;
import std.typetuple;
import std.conv;
import std.traits;

import common;

extern(C) PyObject* test_pyd(int i) {
    string ret;
    foreach(j; 0 .. i) {
        if(j == 0) ret = "Doctor!\0";
        else if(j == 2) ret ~= " ち!\0";
        else ret ~= " Doctor!\0";
    }
    return Funs.utf8_to_python(ret.ptr, ret.length);
}

