import pyd.pyd, pyd.embedded;
import std.exception;
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
}

unittest {
    InterpContext c = new InterpContext();
    c.py_stmts("from testing import *");
    c.py_stmts("boozy = T1()");
    assert(collectException!PythonException(c.py_eval!string("boozy.a()")));
    assert(c.py_eval!string("boozy.b()") == "def");
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
    c.py_stmts("a.e(a)");
    assert(false, "that should not have worked");
}

void main() {}
