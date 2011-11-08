module inherit;

import pyd.pyd;
import std.stdio;

class Base {
    this(int i) { writefln("Base.this(): ", i); }
    void foo() {
        writefln("Base.foo");
    }
    void bar() {
        writefln("Base.bar");
    }
}

class Derived : Base {
    this(int i) { super(i); writefln("Derived.this(): ", i); }
    void foo() {
        writefln("Derived.foo");
    }
}

void call_poly(Base b) {
    writefln("call_poly:");
    b.foo();
}

Base b1, b2, b3;

Base return_poly_base() {
    if (b1 is null) b1 = new Base(1);
    return b1;
}

Base return_poly_derived() {
    if (b2 is null) b2 = new Derived(2);
    return b2;
}

extern(C) void PydMain() {
    def!(call_poly);
    def!(return_poly_base);
    def!(return_poly_derived);

    module_init();

    wrap_class!(
        Base,
        Init!(void function(int)),
        Def!(Base.foo),
        Def!(Base.bar)
    );

    wrap_class!(
        Derived,
        Init!(void function(int)),
        Def!(Derived.foo)
    );
}

