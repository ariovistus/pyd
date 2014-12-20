module example;

import std.stdio;
import pyd.pyd;

struct S {
    int i;
}

S foo() {
    S s;
    s.i = 12;
    return s;
}

void bar(S s) {
    writeln(s);
}

extern(C) void PydMain() {
    ex_d_to_python((S s) => s.i);
    ex_python_to_d((int i) => S(i));

    def!foo();
    def!bar();
    module_init();
}

