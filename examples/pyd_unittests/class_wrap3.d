import pyd.pyd, pyd.embedded;
import deimos.python.pyport: Py_ssize_t;
import std.exception;
import std.stdio;

shared static this() {
    on_py_init({
    add_module!(ModuleName!"testing")();
    });
    py_init();
    on_py_init({
    wrap_class!(Bizzy,
            ModuleName!"testing",
            //Init!(int[]),
            Init!(int,double,string),
            Def!(Bizzy.a, int function(double)), 
            StaticDef!(Bizzy.b, int function(double)),
            Repr!(Bizzy.repr),
            Property!(Bizzy.m, Mode!"r"),
            OpBinary!("+"),
            OpBinary!("*"),
            OpBinary!("^^"),
            OpBinaryRight!("in"),
            OpBinaryRight!("+"),
            OpUnary!("+"),
            OpUnary!("~"),
            OpAssign!("+"),
            OpAssign!("%"),
            OpAssign!("^^"),
            OpIndex!(),
            OpIndexAssign!(),
            OpCompare!(),
            OpSlice!(),
            OpSliceAssign!(),
            OpCall!(double),
            Len!(Bizzy.pylen),
    )();
    wrap_class!(Bizzy2,
            ModuleName!"testing",
            Init!(int[]),
            StaticDef!(Bizzy2.a),
            StaticDef!(Bizzy2.b),
            StaticDef!(Bizzy2.c),
            StaticDef!(Bizzy2.d),
            Def!(Bizzy2.jj),
    )();
    wrap_class!(Bizzy3,
            ModuleName!"testing",
            Init!(int,int),
            Def!(Bizzy3.a),
            Def!(Bizzy3.b),
            Def!(Bizzy3.c),
            Def!(Bizzy3.d),
    )();
    wrap_class!(Bizzy4,
            ModuleName!"testing",
            Property!(Bizzy4.i),
            Repr!(Bizzy4.repr),
            Len!(),
    )();
    wrap_class!(Bizzy5,
            ModuleName!"testing",
            Init!(int,double,string),
            Def!(Bizzy5.a),
    )();
    }, PyInitOrdering.After);

}

class Bizzy {
    int _m;

    int m() { return _m; }

    this(int i, double d = 1.0, string s = "hi") {
    }

    int a(int i){
        return i + 11;
    }
    int a(double d) {
        return cast(int)( d+12);
    }
    static int b(int i){
        return i + 13;
    }
    static int b(double d) {
        return cast(int)( d+14);
    }

    string repr(int i) {
        return "hi";
    }
    string repr() {
        return "bye";
    }
    int opBinary(string op)(int i) {
        static if(op == "+") return i+1;
        else static if(op == "*") return i+2;
        else static if(op == "^^") return i+3;
        else static assert(0);
    }
    bool opBinaryRight(string op)(int i) if(op == "in") {
        return i > 10;
    }

    int opBinaryRight(string op)(int i) if(op == "+") {
        return i + 4;
    }

    void opOpAssign(string op)(int i) {
        static if(op == "+") _m = i + 22;
        else static if(op == "%") _m = i + 33;
        else static if(op == "^^") _m = i + 44;
        else static assert(0);
    }

    int opUnary(string op)() {
        static if(op == "+") return 55;
        else static if(op == "~") return 44;
        else static assert(0);
    }

    override int opCmp(Object p) {
        return 10;
    }

    double opIndex(int i) {
        return i*4.4;
    }

    int[] opSlice(Py_ssize_t a, Py_ssize_t b) {
        return [1,2,3];
    }

    void opIndexAssign(double d, int i) {
        _m = cast(int)(d*1000) + i;
    }

    void opSliceAssign(double d, Py_ssize_t a, Py_ssize_t b) {
        _m = cast(int)(d*1000) + cast(int)(a*10 + b);
    }

    Py_ssize_t pylen(){
        return 401;
    }

    int opCall(double d) {
        return _m + cast(int)(1000 *d);
    }
}

class Bizzy2 {
    int[] js;
    this(int[] i...) {
        js = i.dup;
    }

    int[] jj() {
        return js;
    }

    static int a(int i, double d) {
        return cast(int)(200*d + i);
    }
    static int b(int i, double d = 3.2) {
        return cast(int)(1000*d + 10*i+3);
    }
    static int c(int[] i...) {
        int ret = 0;
        foreach(_i,k; i) {
            ret += 10 ^^ _i * k;
        }
        return ret;
    }

    static string d(int i, int j = 101, string k = "bizbar") {
        import std.string;
        return format("<%s, %s, '%s'>", i,j,k);
    }
}

class Bizzy3{
    this(int i, int j) {
    }

    int a(int i, double d) {
        return cast(int)(100*d + 2*i);
    }
    int b(int i, double d = 3.2) {
        return cast(int)(1000*d + 20*i+4);
    }
    int c(int[] i...) {
        int ret = 0;
        foreach_reverse(_i,k; i) {
            ret += 10 ^^ (i.length-_i-1) * k;
        }
        return ret;
    }

    string d(int i, int j = 102, string k = "bizbar") {
        import std.string;
        return format("<%s, %s, '%s'>", i,j,k);
    }

}

class Bizzy4 {
    int _i = 4;

    @property int i() { return _i; }
    @property void i(int n) { _i = n; }
    @property size_t length() { return 5; }
    @property string repr() { return "cowabunga"; }
}

class Bizzy5 {
    int i;
    double d;
    string s;
    this(int i, double d = 1.0, string s = "hi") {
        this.i = i;
        this.d = d;
        this.s = s;
    }
    string a() {
        import std.string;
        return format("<%s, %s, '%s'>", i,d,s);
    }
}

/+unittest {
    py_stmts(q"{
#bizzy=Bizzy(1,2,3,4,5)
#bizzy=Bizzy(d=7.1,i=4)
bizzy=Bizzy(i=4)
assert bizzy.a(1.0) == 13
assert Bizzy.b(1.0) == 15
assert repr(bizzy) == "bye"
assert bizzy+1 == 2
assert bizzy*1 == 3
assert bizzy**1 == 4
assert 1+bizzy == 5
assert 19 in bizzy
assert 0 not in bizzy 
assert +bizzy == 55
assert ~bizzy == 44
assert bizzy > 1
assert len(bizzy) == 401
assert bizzy[1:2] == [1,2,3]
bizzy += 2
assert bizzy.m == 24
bizzy %= 3
assert bizzy.m == 36
bizzy **= 4
assert bizzy.m == 48
bizzy[2] = 3.3
assert bizzy.m == 3302
bizzy[2:3] = 4.3
assert bizzy.m == 4323
assert bizzy(40.5) == 44823
}", "testing");

py_stmts(q"{
bizzy = Bizzy2(4);
bizzy = Bizzy2([4,5]);
bizzy = Bizzy2(i=4);
bizzy = Bizzy2(i=[4,5]);
}", "testing");

assert(py_eval!int("Bizzy2.a(7, 32.1)","testing") == 6427);
assert(py_eval!int("Bizzy2.a(i=7, d=32.1)","testing") == 6427);
assert(py_eval!int("Bizzy2.a(d=32.1,i=7)","testing") == 6427);
assert(py_eval!int("Bizzy2.b(7, 32.1)","testing") == 32173);
assert(py_eval!int("Bizzy2.b(d=32.1,i=7)","testing") == 32173);
assert(py_eval!int("Bizzy2.b(i=7, d=32.1)","testing") == 32173);
assert(py_eval!int("Bizzy2.b(7)","testing") == 3273);
assert(py_eval!int("Bizzy2.b(i=7)","testing") == 3273);
assert(py_eval!int("Bizzy2.c(7)","testing") == 7);
assert(py_eval!int("Bizzy2.c(i=7)","testing") == 7);
assert(py_eval!int("Bizzy2.c(i=[7])","testing") == 7);
assert(py_eval!int("Bizzy2.c(7,5,6)","testing") == 657);
assert(py_eval!int("Bizzy2.c(i=[7,5,6])","testing") == 657);

py_stmts(q"{
bizzy = Bizzy3(1,2)
}", "testing");
assert(py_eval!int("bizzy.a(7, 32.1)","testing") == 3224);
assert(py_eval!int("bizzy.a(i=7, d=32.1)","testing") == 3224);
assert(py_eval!int("bizzy.a(d=32.1,i=7)","testing") == 3224);
assert(py_eval!int("bizzy.b(7, 32.1)","testing") == 32244);
assert(py_eval!int("bizzy.b(d=32.1,i=7)","testing") == 32244);
assert(py_eval!int("bizzy.b(i=7, d=32.1)","testing") == 32244);
assert(py_eval!int("bizzy.b(7)","testing") == 3344);
assert(py_eval!int("bizzy.b(i=7)","testing") == 3344);
assert(py_eval!int("bizzy.c(7)","testing") == 7);
assert(py_eval!int("bizzy.c(i=7)","testing") == 7);
assert(py_eval!int("bizzy.c(i=[7])","testing") == 7);
assert(py_eval!int("bizzy.c(7,5,6)","testing") == 756);
assert(py_eval!int("bizzy.c(i=[7,5,6])","testing") == 756);

py_stmts(q"{
bizzy = Bizzy4()
}", "testing");
assert(py_eval!int("bizzy.i","testing") == 4);
py_stmts(q"{
bizzy.i = 10
}", "testing");
assert(py_eval!int("bizzy.i","testing") == 10);
assert(py_eval!int("len(bizzy)","testing") == 5);
assert(py_eval!string("repr(bizzy)","testing") == "cowabunga");

}+/
unittest{
    InterpContext c = new InterpContext();
    c.py_stmts("from testing import *");
    c.py_stmts("bizzy = Bizzy(i=4)");
    c.py_stmts("assert bizzy.a(1.0) == 13");
    c.py_stmts("assert Bizzy.b(1.0) == 15");
    c.py_stmts("assert repr(bizzy) == 'bye'");
    c.py_stmts("assert bizzy+1 == 2");
    c.py_stmts("assert bizzy*1 == 3");
    c.py_stmts("assert bizzy**1 == 4");
    c.py_stmts("assert 1+bizzy == 5");
    c.py_stmts("assert 19 in bizzy");
    c.py_stmts("assert 0 not in bizzy ");
    c.py_stmts("assert +bizzy == 55");
    c.py_stmts("assert ~bizzy == 44");
    c.py_stmts("assert bizzy > 1");
    c.py_stmts("assert len(bizzy) == 401");
    c.py_stmts("assert bizzy[1:2] == [1,2,3]");
    c.py_stmts("bizzy += 2");
    c.py_stmts("assert bizzy.m == 24");
    c.py_stmts("bizzy %= 3");
    c.py_stmts("assert bizzy.m == 36");
    c.py_stmts("bizzy **= 4");
    c.py_stmts("assert bizzy.m == 48");
    c.py_stmts("bizzy[2] = 3.5");
    c.py_stmts("assert bizzy.m == 3502");
    c.py_stmts("bizzy[2:3] = 4.5");
    c.py_stmts("assert bizzy.m == 4523");
    c.py_stmts("assert bizzy(40.5) == 45023");

    c.py_stmts("bizzy = Bizzy2(4);");
    c.py_stmts("assert bizzy.jj() == [4]");
    c.py_stmts("bizzy = Bizzy2(4,5);");
    c.py_stmts("assert bizzy.jj() == [4,5]");
    c.py_stmts("bizzy = Bizzy2(i=4);");
    c.py_stmts("assert bizzy.jj() == [4]");
    c.py_stmts("bizzy = Bizzy2(i=[4,5]);");
    c.py_stmts("assert bizzy.jj() == [4,5]");

    assert(c.py_eval!int("Bizzy2.a(7, 32.1)") == 6427);
    assert(c.py_eval!int("Bizzy2.a(i=7, d=32.1)") == 6427);
    assert(c.py_eval!int("Bizzy2.a(d=32.1,i=7)") == 6427);
    assert(c.py_eval!int("Bizzy2.b(7, 32.1)") == 32173);
    assert(c.py_eval!int("Bizzy2.b(d=32.1,i=7)") == 32173);
    assert(c.py_eval!int("Bizzy2.b(i=7, d=32.1)") == 32173);
    assert(c.py_eval!int("Bizzy2.b(7)") == 3273);
    assert(c.py_eval!int("Bizzy2.b(i=7)") == 3273);
    assert(c.py_eval!int("Bizzy2.c(7)") == 7);
    assert(c.py_eval!int("Bizzy2.c(i=7)") == 7);
    assert(c.py_eval!int("Bizzy2.c(i=[7])") == 7);
    assert(c.py_eval!int("Bizzy2.c(7,5,6)") == 657);
    assert(c.py_eval!int("Bizzy2.c(i=[7,5,6])") == 657);
    assert(c.py_eval!string("Bizzy2.d(i=7, k='foobiz')") == "<7, 101, 'foobiz'>");
    // unexpected arguments (s in this case) are invalid.
    assert(collectException!PythonException(
                c.py_eval!string("Bizzy2.d(i=7, s='foobiz')")));

    c.py_stmts("bizzy = Bizzy3(1,2)");
    assert(c.py_eval!int("bizzy.a(7, 32.1)") == 3224);
    assert(c.py_eval!int("bizzy.a(i=7, d=32.1)") == 3224);
    assert(c.py_eval!int("bizzy.a(d=32.1,i=7)") == 3224);
    assert(c.py_eval!int("bizzy.b(7, 32.1)") == 32244);
    assert(c.py_eval!int("bizzy.b(d=32.1,i=7)") == 32244);
    assert(c.py_eval!int("bizzy.b(i=7, d=32.1)") == 32244);
    assert(c.py_eval!int("bizzy.b(7)") == 3344);
    assert(c.py_eval!int("bizzy.b(i=7)") == 3344);
    assert(c.py_eval!int("bizzy.c(7)") == 7);
    assert(c.py_eval!int("bizzy.c(i=7)") == 7);
    assert(c.py_eval!int("bizzy.c(i=[7])") == 7);
    assert(c.py_eval!int("bizzy.c(7,5,6)") == 756);
    assert(c.py_eval!int("bizzy.c(i=[7,5,6])") == 756);
    assert(c.py_eval!string("bizzy.d(i=7, k='foobiz')") == "<7, 102, 'foobiz'>");

    c.py_stmts("bizzy = Bizzy4()");
    assert(c.py_eval!int("bizzy.i") == 4);
    c.py_stmts("bizzy.i = 10");
    assert(c.py_eval!int("bizzy.i") == 10);
    assert(c.py_eval!int("len(bizzy)") == 5);
    assert(c.py_eval!string("repr(bizzy)") == "cowabunga");

    c.py_stmts("boozy = Bizzy5(1)");
    assert(c.py_eval!string("boozy.a()") == "<1, 1, 'hi'>");
    c.py_stmts("boozy = Bizzy5(1, d=2.0)");
    assert(c.py_eval!string("boozy.a()") == "<1, 2, 'hi'>");
    c.py_stmts("boozy = Bizzy5(1, s='ten')");
    assert(c.py_eval!string("boozy.a()") == "<1, 1, 'ten'>");

}

void main() {}
