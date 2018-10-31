import pyd.pyd, pyd.embedded;
import deimos.python.Python;
import std.string;

struct Foo1{
    int i;
    int j;
    int k;

    this(int _i, int _j, int _k) {
        i=_i; j=_j; k=_k;
    }

    int bar() {
        return i+j*k;
    }
}

struct Foo2 {
    int i;
    string[] s;
    dchar[][] d;
    immutable(dchar)[][] d2;
}

struct Foo3 {
    int i;
    Foo4 foo;
}

struct Foo4 {
    int j;
}

struct Foo5 {
    Foo4 foo;
}

struct Foo6 {
    import std.datetime: DateTime;
    DateTime dateTime;
}

static this() {
    on_py_init({
    add_module!(ModuleName!"testing")();
    });
    on_py_init({
        wrap_struct!(
            Foo1,
            ModuleName!"testing",
            Init!(int,int,int),
            Member!("i"),
            Member!("j", Mode!"r"),
            Member!("k", Mode!"w"),
            Def!(Foo1.bar),
        )();
        wrap_struct!(
            Foo2,
            ModuleName!"testing",
            Member!("i"),
            Member!("s"),
            Member!("d"),
            Member!("d2"),
        )();
        wrap_struct!(
            Foo3,
            ModuleName!"testing",
            Member!"i",
            Member!"foo"
        )();
        wrap_struct!(
            Foo4,
            ModuleName!"testing",
            Member!"j",
        )();
        wrap_struct!(
            Foo5,
            ModuleName!"testing",
            Member!"foo",
        )();
        wrap_struct!(
            Foo6,
            ModuleName!"testing",
            Member!"dateTime",
        )();
    }, PyInitOrdering.After);

    py_init();
}


unittest {
    py_stmts(q"{
foo1 = Foo1(2,3,4);
assert foo1.i == 2
}","testing");
}

unittest {
    //const(Foo1) fooboo;
    //d_to_python(fooboo);
}

unittest {
    auto context = new InterpContext();
    Foo3 a;
    a.i = 1;
    a.foo.j = 2;
    context.a = &a;
    Foo4* x = context.py_eval("a.foo").to_d!(Foo4*)();
    assert(x == &a.foo);
    context.py_stmts(q"{
a.foo.j = 3
assert a.foo.j == 3
}","testing");
}

unittest {
    auto context = new InterpContext();
    context.py_stmts(q"{
    from testing import Foo3
    a3 = Foo3()
}","testing");
    Foo3* x = context.py_eval("a3").to_d!(Foo3*)();
    Foo4* x4 = context.py_eval("a3.foo").to_d!(Foo4*)();
    assert(&x.foo == x4);
}

unittest {
    auto context = new InterpContext();
    Foo3 a;
    a.i = 1;
    a.foo.j = 2;
    context.a = a;
    context.py_stmts(q"{
a.foo.j = 3
assert a.foo.j == 3
}","testing");
}

unittest {
    auto context = new InterpContext();
    Foo5 a;
    a.foo.j = 2;
    context.a = &a;
    Foo4* x4 = context.py_eval("a.foo").to_d!(Foo4*)();
    assert (x4.j == 2);
}


unittest {
    Foo5 a;
    auto x = py(&a);
    assert (x.toString().startsWith("<testing.Foo5"));
}


unittest {

    auto context = new InterpContext();
    context.py_stmts(q"{
    from testing import Foo6
    from datetime import datetime as Date
    f = Foo6(Date(2018, 7, 3))
    y = f.dateTime.year
}", "testing");
}

void main(){}
