import pyd.pyd;
import std.stdio;

void foo(int i) {
    writefln("You entered %s", i);
}

void bar(int i) {
    writefln("bar: i = %s", i);
}

void bar(string s) {
    writefln("bar: s = %s", s);
}

void baz(int i=10, string s="moo") {
    writefln("i = %s\ns = %s", i, s);
}

extern (C) void PydMain() {
    // Plain old function
    def!(foo)();
    // Wraps the lexically first function under the given name
    def!(bar, PyName!"bar1")();
    // Wraps the function of the specified type
    def!(bar, PyName!"bar2", void function(string))();
    // Wraps the function with default arguments
    def!(baz)();

    module_init();
}
