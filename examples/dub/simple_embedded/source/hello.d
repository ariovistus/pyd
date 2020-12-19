module hello;

import std.stdio;
import pyd.pyd, pyd.embedded;

shared static this() {
    py_init();
}

void main() {
    writeln(py_eval!string("'1 + %s' % 2"));

    auto c = py_eval("complex(2,-1)");
    auto h = c.__hash__();
    writeln(c);
    writeln(h);
}
