module testdll;

import python;
import pyd.pyd;
import std.stdio, std.string;

void foo() {
    writeln("20 Monkey");
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
    int opSlice(size_t i1, size_t i2) {
        writeln(i1, " ", i2);
        return 12;
    }
    int opIndex(int x, int y) {
        writeln(x, " ", y);
        return x+y;
    }
    Foo opBinary(string op)(Foo f) if(op == "+")
    { 
        return new Foo(m_i + f.m_i); 
    }

    int opApply(int delegate(ref int, ref int) dg) {
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
    return { writeln("Delegate works!"); };
}

void dg_test(void delegate() dg) {
    dg();
}

class Bar {
    int[] m_a;
    this() { }
    this(int[] i ...) { m_a = i; }
    int opApply(int delegate(ref int) dg) {
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
        writeln(s);
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
    writeln(a.i);
}

extern(C) void PydMain() {
    pragma(msg, "testdll.PydMain");
    ex_d_to_python(delegate int(A a) { return a.i; });
    ex_python_to_d(delegate A(int i) { A a; a.i = i; return a; });

    def!(foo);
    // Python does not support function overloading. This requires us to wrap
    // an overloading function under a different name. Note that if the
    // overloaded function is not the lexically first, the type of the function
    // must be specified
    def!(foo, PyName!"foo2", void function(int));
    pragma(msg, bar.mangleof);
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
    wrap_class!(
        Foo,
        PyName!"Foo",
        Docstring!"A sample class.",
        Init!(int), 
        Init!(int, int),
        Property!(Foo.i, Docstring!"A sample property of Foo."),
        OpBinary!("+"),
        Def!(Foo.foo, Docstring!"A sample method of Foo."),
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
        Def!(Foo.z), */
    )();

    wrap_struct!(
        S,
        Docstring!"A sample struct.",
        Def!(S.write_s, Docstring!"A struct member function."),
        Member!("i", Docstring!"One sample data member of S."),
        Member!("s", Docstring!"Another sample data member of S."),
    )();
}

