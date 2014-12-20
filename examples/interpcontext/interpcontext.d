module interpcontext;

import std.stdio;
import pyd.pyd, pyd.embedded;

shared static this() {
    py_init();
}

void main() {
    auto context = new InterpContext();
    context.a = 2;
    context.py_stmts("print ('1 + %s' % a)");
}




