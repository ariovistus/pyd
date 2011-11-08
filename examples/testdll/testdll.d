module testdll;

import python;
import pyd.pyd;
import std.stdio, std.string;

void foo() {
    writefln("20 Monkey");
}

void foo(int i) {
    writefln("You entered %s", i);
}

string bar(int i) {
    if (i > 10) {
        return "It's greater than 10!";
    } else {
        return "It's less than 10!";
    }
}

void baz(int i=10, string s="moo") {
    writefln("i = %s\ns = %s", i, s);
}

class Foo {
    int m_i;
    this() { }
    this(int i) {
        m_i = i;
    }
    this(int i, int j) {
        m_i = i + j;
    }
    void foo() {
        writefln("Foo.foo(): i = %s", m_i);
    }
    int length() { return 10; }
    int opSlice(int i1, int i2) {
        writefln(i1, " ", i2);
        return 12;
    }
    int opIndex(int x, int y) {
        writefln(x, " ", y);
        return x+y;
    }
    Foo opAdd(Foo f) { return new Foo(m_i + f.m_i); }
    int opApply(int delegate(inout int, inout int) dg) {
        int result = 0;
        int j;
        for (int i=0; i<10; ++i) {
            j = i+1;
            result = dg(i, j);
            if (result) break;
        }
        return result;
    }
    int i() { return m_i; }
    void i(int j) { m_i = j; }
    void a() {}
    void b() {}
    void c() {}
    void d() {}
    void e() {}
    void f() {}
    void g() {}
    void h() {}
    void j() {}
    void k() {}
    void l() {}
    void m() {}
    void n() {}
    void o() {}
    void p() {}
    void q() {}
    void r() {}
    void s() {}
    void t() {}
    void u() {}
    void v() {}
    void w() {}
    void x() {}
    void y() {}
    void z() {}
}

void delegate() func_test() {
    return { writefln("Delegate works!"); };
}

void dg_test(void delegate() dg) {
    dg();
}

class Bar {
    int[] m_a;
    this() { }
    this(int[] i ...) { m_a = i; }
    int opApply(int delegate(inout int) dg) {
        int result = 0;
        for (int i=0; i<m_a.length; ++i) {
            result = dg(m_a[i]);
            if (result) break;
        }
        return result;
    }
}

struct S {
    int i;
    char[] s;
    void write_s() {
        writefln(s);
    }
}


struct A {
    int i;
}

Foo spam(Foo f) {
    f.foo();
    Foo g = new Foo(f.i + 10);
    return g;
}

void throws() {
    throw new Exception("Yay! An exception!");
}

A conv1() {
    A a;
    a.i = 12;
    return a;
}
void conv2(A a) {
    writefln(a.i);
}

mixin _wrap_class!(
    Foo,
    "Foo",
    Init!(void delegate(int), void delegate(int, int)),
    Property!(Foo.i, "A sample property of Foo."),
    Def!(Foo.foo, "A sample method of Foo."),
    Def!(Foo.a),
    Def!(Foo.b),
    Def!(Foo.c),
    Def!(Foo.d),
    Def!(Foo.e),
    Def!(Foo.f),
    Def!(Foo.g),
    Def!(Foo.h),
    Def!(Foo.j),
    Def!(Foo.k),
    Def!(Foo.l),
    Def!(Foo.m),
    Def!(Foo.n)/*, // Maximum length
    Def!(Foo.o),
    Def!(Foo.p),
    Def!(Foo.q),
    Def!(Foo.r),
    Def!(Foo.s),
    Def!(Foo.t),
    Def!(Foo.u),
    Def!(Foo.v),
    Def!(Foo.w),
    Def!(Foo.x),
    Def!(Foo.y),
    Def!(Foo.z)*/
) F;

extern(C) void PydMain() {
    pragma(msg, "testdll.PydMain");
    d_to_python(delegate int(A a) { return a.i; });
    python_to_d(delegate A(int i) { A a; a.i = i; return a; });

    def!(foo);
    // Python does not support function overloading. This allows us to wrap
    // an overloading function under a different name. Note that if the
    // overload accepts a different number of minimum arguments, that number
    // must be specified.
    def!(foo, "foo2", void function(int), 1);
    def!(bar);
    // Default argument support - Now implicit!
    def!(baz);
    def!(spam);
    def!(func_test);
    def!(dg_test);
    def!(throws);
    def!(conv1);
    def!(conv2);

    module_init();

    F.wrap_class("A sample class.");

    wrap_struct!(
        S,
        Def!(S.write_s, "A struct member function."),
        Member!("i", "One sample data member of S."),
        Member!("s", "Another sample data member of S.")
    ) ("A sample struct.");
}

