module arraytest;

import pyd.pyd;
import std.stdio : writefln, writef;
import std.string : format;

class Foo {
    int i;
    this(int j) { i = j; }
    void bar() {
        writefln("Foo.bar: %s", i);
    }
    string toString() {
        return format("{%s}",i);
    }
}

Foo[] global_array;

Foo[] get() {
    writefln("get: %s", global_array);
    return global_array;
}
void set(Foo[] a) {
    writefln("set: a: %s, global: %s", a, global_array);
    global_array = a;
    writefln("set: global now: %s", global_array);
}
Foo test() {
    return new Foo(10);
}

extern(C) void PydMain() {
    global_array.length = 5;
    for (int i=0; i<5; ++i) {
        global_array[i] = new Foo(i);
    }
    def!(get)();
    def!(set)();
    def!(test)();
    module_init();
    wrap_class!(
        Foo,
        Init!(int),
        Repr!(Foo.toString),
        Def!(Foo.bar)
    )();
}
