import pyd.pyd, pyd.embedded;
import std.exception;
import std.algorithm: countUntil;
import std.stdio;

shared static this() {
    on_py_init({
            add_module!(ModuleName!"testing")();
    });
    py_init();
    on_py_init({
    wrap_class!(T1,
            ModuleName!"testing",
            Def!(T1.a),
            Def!(T1.b),
            Def!(T1.c),
            Def!(T1.d),
            Def!(T1.e),
            Def!(T1.v1),
            Def!(T1.im1),
            Property!(T1.p1),
            Property!(T1.p1i),
            Property!(T1.p1c),
            Property!(T1.p1w),
    )();
    }, PyInitOrdering.After);

}

class T1 {
    int i;
    string s;

    string a() immutable {
        return "abc";
    }

    string b() const {
        return "def";
    }

    void c(const(T1) t) {
        writeln(t.b());
    }
    void d(immutable(T1) t) {
        writeln(t.a());
    }
    void e(T1 t) {
    }

    @property void p1(int i) {
    }
    @property int p1() {
        return 100;
    }

    @property int p1i() immutable {
        return 200;
    }

    @property int p1c() const {
        return 300;
    }

    @property int p1w() inout {
        return 400;
    }

    void v1() {
        int i = 1 + 2;
    }

    void im1(immutable(T1) tz) {
    }
}

unittest {
    InterpContext c = new InterpContext();
    c.py_stmts("from testing import *");
    c.py_stmts("boozy = T1()");
    assert(collectException!PythonException(c.py_eval!string("boozy.a()")));
    assert(c.py_eval!string("boozy.b()") == "def");
    assert(collectException!PythonException(c.py_eval!string("z = boozy.p1i")));
    assert(c.py_eval!int("boozy.p1c") == 300);
}

unittest {
    immutable(T1) t = cast(immutable) new T1();

    auto p = d_to_python(t);
    handle_exception();
}

unittest {
    InterpContext c = new InterpContext();
    c.py_stmts("from testing import *");
    auto a = new T1();
    c.f = &a.e;
    c.a = a;
    c.py_stmts("a.c(a)");
    c.py_stmts("a.e(a)");
    try {
        c.py_stmts("a.im1(a)");
        assert(false, "that should have required an immutable param");
    }catch(PythonException ex) {
        string msg ="constness mismatch required: immutable, found: mutable";
        assert(countUntil(ex.toString(), msg) != -1);
    }
}

void main() {}
