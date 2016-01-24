import pyd.pyd, pyd.embedded;
import std.traits;
import std.functional;
import std.range;
import std.algorithm;
import std.exception;
import std.datetime;
import deimos.python.Python;
import std.stdio;

static this() {
    on_py_init({
    add_module!(ModuleName!"testing")();
    });
    py_init();
}

auto cantconvert(E)(lazy E e) {
    return collectException!PydConversionException(e);
}

version(Python_2_6_Or_Later) {
    void displaybuffer(PydObject.BufferView buf) {
        writefln("buf.has_simple: %x", buf.has_simple);
        writefln("buf.has_nd: %x", buf.has_nd);
        writefln("buf.has_strides: %x", buf.has_strides);
        writefln("buf.has_indirect: %x", buf.has_indirect);
        writefln("buf.c_contiguous: %x", buf.c_contiguous);
        writefln("buf.fortran_contiguous: %x", buf.fortran_contiguous);
        writefln("buf.buf: %x", buf.buf.ptr);
        writefln("buf.len: %s", buf.buf.length);
        writefln("buf.format: %s", buf.format);
        writefln("buf.itemsize: %s", buf.itemsize);
        writefln("buf.ndim: %s", buf.ndim);
        writefln("buf.shape: %s", buf.shape);
        writefln("buf.strides: %s", buf.strides);
        writefln("buf.suboffsets: %s", buf.suboffsets);
    }
}


unittest {
    import std.bigint;
    // python long -> BigInt
    assert(py_eval!BigInt("6 ** 603") == BigInt("6") ^^ 603);
    assert(py_eval!BigInt("-6 ** 603") == -BigInt("6") ^^ 603);
    // BigInt -> python long
    assert(py(BigInt("7") ^^ 47) == py_eval("7 ** 47"));
    assert(py(-BigInt("7") ^^ 47) == py_eval("-7 ** 47"));
}

unittest {
    py_stmts(`from array import array; a = array('i', [44,33,22,11]);`, "testing");
    assert(py_eval!(int[])("a", "testing") == [44,33,22,11]);
    assert(py_eval!(int[4])("a", "testing") == [44,33,22,11]);
    double[] g = [5.5,4.5,3.5];

    assert(python_to_d!(double[])(d_to_python_array_array(g)) == g);
}

// numpy unittests - numpy supports new buffer interface with PyBUF_ND,
// PyBUF_C_CONTIGUOUS, and PyBUF_F_CONTIGUOUS. handy for testing.
version(Python_2_6_Or_Later) {
unittest {
    import std.stdio;

    PydObject numpy;
    try {
        numpy = py_import("numpy");
    }catch(PythonException e) {
        writeln("If you had numpy, we could do some more unittests");
    }

    if(numpy) {
        py_stmts(
                "from numpy import eye, ndarray\n"
                "a = eye(4,k=1)\n"
                "b = eye(3,4)\n"
                "f = ndarray(shape=[3,4], buffer=b, order='F')\n"
                ,
                "testing");
        assert(py_eval!(double[][])("a","testing") == 
                [[0, 1, 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1],
                 [0, 0, 0, 0]]);
        assert(py_eval!(double[4][4])("a","testing") == 
                [[0, 1, 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1],
                 [0, 0, 0, 0]]);
        assert(py_eval!(double[][4])("a","testing") == 
                [[0, 1, 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1],
                 [0, 0, 0, 0]]);
        assert(py_eval!(double[4][])("a","testing") == 
                [[0, 1, 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1],
                 [0, 0, 0, 0]]);
        assert(*py_eval!(double[4][4]*)("a","testing") == 
                [[0, 1, 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1],
                 [0, 0, 0, 0]]);
        assert(py_eval!(double[][])("b","testing") == 
                [[1, 0, 0, 0],
                 [0, 1, 0, 0],
                 [0, 0, 1, 0]]);
        assert(py_eval!(double[4][3])("b","testing") == 
                [[1, 0, 0, 0],
                 [0, 1, 0, 0],
                 [0, 0, 1, 0]]);
        assert(py_eval!(double[][3])("b","testing") == 
                [[1, 0, 0, 0],
                 [0, 1, 0, 0],
                 [0, 0, 1, 0]]);
        assert(py_eval!(double[4][])("b","testing") == 
                [[1, 0, 0, 0],
                 [0, 1, 0, 0],
                 [0, 0, 1, 0]]);
        assert(*py_eval!(double[4][3]*)("b","testing") == 
                [[1, 0, 0, 0],
                 [0, 1, 0, 0],
                 [0, 0, 1, 0]]);
        assert(py_eval!(double[][])("f","testing") == 
                [[1, 0, 0, 0],
                 [0, 0, 0, 1],
                 [0, 1, 0, 0]]);
        assert(py_eval!(double[4][3])("f","testing") == 
                [[1, 0, 0, 0],
                 [0, 0, 0, 1],
                 [0, 1, 0, 0]]);
        assert(py_eval!(double[][3])("f","testing") == 
                [[1, 0, 0, 0],
                 [0, 0, 0, 1],
                 [0, 1, 0, 0]]);
        assert(py_eval!(double[4][])("f","testing") == 
                [[1, 0, 0, 0],
                 [0, 0, 0, 1],
                 [0, 1, 0, 0]]);
        assert(*py_eval!(double[4][3]*)("f","testing") == 
                [[1, 0, 0, 0],
                 [0, 0, 0, 1],
                 [0, 1, 0, 0]]);

        assert(py_eval("f","testing").buffer_view().format == "d");
        // this won't work because f is a matrix of doubles
        assert(cantconvert(py_eval!(float[][])("f","testing")));

        auto b = py_eval!(double[][])("b","testing"); 
        import pyd.extra;
        assert(python_to_d!(double[][])(d_to_python_numpy_ndarray(b))
                ==
                [[1, 0, 0, 0],
                 [0, 1, 0, 0],
                 [0, 0, 1, 0]]);
    }
}
}

// tests on MatrixInfo utility template
unittest {
    alias MatrixInfo!(double[][]) M1;
    static assert(M1.ndim == 2);
    static assert(M1.dimstring == "[*,*]");
    static assert(is(M1.unqual == double[][]));
    static assert(is(M1.MatrixElementType == double));
    alias MatrixInfo!(const(double[4][5])) M2;
    static assert(M2.ndim == 2);
    static assert(M2.dimstring == "[5,4]");
    static assert(is(M2.unqual == double[4][5]));
    static assert(is(M2.MatrixElementType == const(double)));
    alias MatrixInfo!(string[4][5]) M3;
    static assert(M3.ndim == 2);
    static assert(M3.dimstring == "[5,4]");
    static assert(is(M3.unqual == string[4][5]));
    static assert(is(M3.MatrixElementType == string));
}

// bytearray tests - bytearray supports the new buffer interface with
// PyBUF_ND and PyBUF_C_CONTIGUOUS
version(Python_2_6_Or_Later) {
unittest {
    version(Python_3_0_Or_Later) {
        py_stmts(
                "a = bytearray('abcdefg', 'ascii')\n"
                , "testing");
    }else{
        py_stmts(
                "a = bytearray('abcdefg')\n"
                , "testing");
    }
    auto a = py_eval("a","testing");
    auto b = a.buffer_view();
    assert(py_eval!(ubyte[])("a", "testing") == cast(ubyte[]) "abcdefg");
    PyObject* a_ptr = Py_INCREF(a.ptr);
    scope(exit) Py_DECREF(a_ptr);
    // python_to_d should be calling this function
    assert(python_buffer_to_d!(ubyte[])(a_ptr) == cast(ubyte[]) "abcdefg");
    // bytearray's elements are unsigned
    assert(cantconvert(python_buffer_to_d!(byte[])(a_ptr)));
    // with char[], python_to_d probably isn't calling this function, but anyways
    // char[]'s element type is dchar. Go figure.
    assert(cantconvert(python_buffer_to_d!(char[])(a_ptr)));
}
}


// test arbirary ranges
unittest{
    auto z = (iota(10));
    alias typeof(z) Z;
    alias py_def!(
            "def foozit(a):\n"
            " import itertools\n"
            " b = list(itertools.islice(a, 0, 2))\n"
            " return b,a"
            ,
            "testing", Tuple!(int[],Z) function(Z)) Foo1;
    auto t = Foo1(z);
    auto ix = t[0];
    z = t[1];
    import std.conv;
    assert(ix == [0, 1], to!string(ix));
    assert(equal(z, [2,3,4,5,6,7,8,9]));

}

unittest {
    assert(python_to_d!int(d_to_python(15)) == 15);
    assert(python_to_d!float(d_to_python(1.0f)) == 1.0f);
    import std.complex;
    assert(python_to_d!(Complex!double)(d_to_python(complex(2.0,3.0))) == complex(2.0,3.0));
    import std.typecons;
    assert(python_to_d!(Tuple!(int,double))(d_to_python(tuple(2,3.0))) == tuple(2,3.0));
    assert(python_to_d!(Tuple!(int, "a",double, "b"))(d_to_python(Tuple!(int, "a", double, "b")(2,3.0))) == Tuple!(int,"a",double,"b")(2,3.0));
}

unittest {
    auto py = py_eval("{'a': 'a'}");
    auto d = python_to_d!(string[string])(cast(PyObject*) py.ptr());
    assert(d["a"] == "a");
}

unittest {
    assert(py_eval!byte("int(30)") == 30);
    assert(py_eval!byte(format("int(%s)", byte.max)) == byte.max);
    assert(py_eval!byte(format("int(%s)", byte.min)) == byte.min);
    assert(py_eval!ubyte("int(30)") == 30);
    version(Python_3_0_Or_Later) {
    }else{
        assert(py_eval!byte("long(30)") == 30);
        assert(py_eval!ubyte("long(30)") == 30);
        assert(py_eval!byte(format("long(%s)", byte.max)) == byte.max);
        assert(py_eval!byte(format("long(%s)", byte.min)) == byte.min);
        assert(py_eval!ubyte(format("long(%s)", ubyte.max)) == ubyte.max);
        assert(py_eval!ubyte(format("long(%s)", ubyte.min)) == ubyte.min);
        assert(py_eval!short("long(30)") == 30);
        assert(py_eval!ushort("long(30)") == 30);
        assert(py_eval!int("long(300)") == 300);
        assert(py_eval!uint("long(300)") == 300);
        assert(py_eval!long("long(30)") == 30);
        assert(py_eval!ulong("long(30)") == 30);
        assert(py_eval!long(format("long(%s)", long.max)) == long.max);
        assert(py_eval!long(format("long(%s)", long.min)) == long.min);
        assert(py_eval!ulong(format("long(%s)", ulong.max)) == ulong.max);
    }
    assert(py_eval!ubyte(format("int(%s)", ubyte.max)) == ubyte.max);
    assert(py_eval!ubyte(format("int(%s)", ubyte.min)) == ubyte.min);
    assert(py_eval!short("int(30)") == 30);
    assert(py_eval!ushort("int(30)") == 30);
    assert(py_eval!int("int(300)") == 300);
    assert(py_eval!uint("int(300)") == 300);
    assert(py_eval!long("int(30)") == 30);
    assert(py_eval!ulong("int(30)") == 30);

    // values out of bounds are out of bounds.

    assert(cantconvert(py_eval!byte("int(300)")));
    assert(cantconvert(py_eval!ubyte("int(300)")));
    //assert(cantconvert(py_eval!ubyte("int(-1)")));

    assert(py(cast(byte)1) == py(1));
}

unittest {
    assert(py_eval!(int[])("[4,5,7]") == [4,5,7]);
    assert(py_eval!(int[3])("[4,5,7]") == [4,5,7]);
    assert(py_eval!(immutable(int)[])("[4,5,7]") == [4,5,7]);
    assert(py_eval!(immutable(int)[3])("[4,5,7]") == [4,5,7]);
    assert(py_eval!(immutable(int[]))("[4,5,7]") == [4,5,7]);
    assert(py_eval!(immutable(int[3]))("[4,5,7]") == [4,5,7]);
}

unittest {
    assert(equal(py_eval!(PydInputRange!int)("[5,6,7,8]"), [5,6,7,8]));
    version(Python_3_0_Or_Later) {
        assert(equal(py_eval!(PydInputRange!int)("range(2, 20)"), iota(2,20)));
    }else{
        assert(equal(py_eval!(PydInputRange!int)("xrange(2, 20)"), iota(2,20)));
    }
}

// string tests
unittest {
    string simple = "abc123";
    auto si = py(simple);
    assert(si.to_d!string() == "abc123");
    assert(si.to_d!wstring() == "abc123"w);
    assert(si.to_d!dstring() == "abc123"d);
    wstring simplew = "abc123"w;
    si = py(simplew);
    assert(si.to_d!string() == "abc123");
    assert(si.to_d!wstring() == "abc123"w);
    assert(si.to_d!dstring() == "abc123"d);
    dstring simpled = "abc123"d;
    si = py(simpled);
    assert(si.to_d!string() == "abc123");
    assert(si.to_d!wstring() == "abc123"w);
    assert(si.to_d!dstring() == "abc123"d);

    string asian = "ちりめん";
    si = py(asian);
    assert(si.to_d!string() == "ちりめん");
    assert(si.to_d!wstring() == "ちりめん"w);
    assert(si.to_d!dstring() == "ちりめん"d);
    wstring asianw = "ちりめん";
    si = py(asianw);
    assert(si.to_d!string() == "ちりめん");
    assert(si.to_d!wstring() == "ちりめん"w);
    assert(si.to_d!dstring() == "ちりめん"d);
    dstring asiand = "ちりめん";
    si = py(asiand);
    assert(si.to_d!string() == "ちりめん");
    assert(si.to_d!wstring() == "ちりめん"w);
    assert(si.to_d!dstring() == "ちりめん"d);
}

unittest {
    auto datetime = DateTime(1999, 1, 5, 4, 31, 39);
    auto date = Date(1998, 2, 4);
    auto systime = SysTime(datetime);
    auto time = TimeOfDay(4, 32, 33);
    auto context = new InterpContext();
    context.d = datetime;
    context.d2 = date;
    context.s = systime;
    context.t = time;
    context.py_stmts("
        from datetime import datetime, date, time
        assert isinstance(d, datetime)
        assert d.year == 1999
        assert d.month == 1
        assert d.day == 5
        assert d.hour == 4
        assert d.minute == 31
        assert d.second == 39

        assert isinstance(d2, date)
        assert d2.year == 1998
        assert d2.month == 2
        assert d2.day == 4

        assert isinstance(s, datetime)
        assert s.year == 1999
        assert s.month == 1
        assert s.day == 5
        assert s.hour == 4
        assert s.minute == 31
        assert s.second == 39

        assert isinstance(t, time)
        assert t.hour == 4
        assert t.minute == 32
        assert t.second == 33
    ");
}

unittest {
    auto context = new InterpContext();
    context.py_stmts("
        from datetime import datetime, date, time
        d1 = datetime(2011, 4, 21, 4, 31, 39)
        d2 = date(2012, 5, 12)
        t1 = time(4, 32, 40)
    ");

    auto datetime = context.d1.to_d!DateTime();
    assert(datetime.year == 2011);
    assert(datetime.month == 4);
    assert(datetime.day == 21);
    assert(datetime.hour == 4);
    assert(datetime.minute == 31);
    assert(datetime.second == 39);

    auto datetime2 = context.d2.to_d!DateTime();
    assert(datetime2.year == 2012);
    assert(datetime2.month == 5);
    assert(datetime2.day == 12);
    assert(datetime2.hour == 0);
    assert(datetime2.minute == 0);
    assert(datetime2.second == 0);

    auto date = context.d1.to_d!Date();
    assert(date.year == 2011);
    assert(date.month == 4);
    assert(date.day == 21);

    auto date2 = context.d2.to_d!Date();
    assert(date2.year == 2012);
    assert(date2.month == 5);
    assert(date2.day == 12);

    auto systime1 = context.d1.to_d!SysTime();
    assert(systime1.year == 2011);
    assert(systime1.month == 4);
    assert(systime1.day == 21);
    assert(systime1.hour == 4);
    assert(systime1.minute == 31);
    assert(systime1.second == 39);

    auto systime2 = context.d2.to_d!SysTime();
    assert(systime2.year == 2012);
    assert(systime2.month == 5);
    assert(systime2.day == 12);
    assert(systime2.hour == 0);
    assert(systime2.minute == 0);
    assert(systime2.second == 0);

    auto time1 = context.t1.to_d!TimeOfDay();
    assert(time1.hour == 4);
    assert(time1.minute == 32);
    assert(time1.second == 40);

    auto time2 = context.d1.to_d!TimeOfDay();
    assert(time2.hour == 4);
    assert(time2.minute == 31);
    assert(time2.second == 39);
}

class G1(string name) {
    int i;
    this(int _i){ i = _i; }

    override bool opEquals(Object obj) {
        G1!name g = cast(G1!name) obj;
        if(!g) return false;
        return i == g.i;
    }
}

unittest {

    class Conv {
        int opCall(G1!"joe" g) {
            return g.i;
        }
    }

    class Conv2 {
        G1!"joe" opCall(int i) {
            return new G1!"joe"(i);
        }
    }
    static if(!__traits(compiles, {
                alias unaryFun!"a.i" uConv;
                alias uConv!(G1!"martin") mConv;
                })) {
        import std.stdio;
        writeln("Can't run this unit test due to dmd issue 12426");
    }else {
        alias unaryFun!"a.i" uConv;
        alias uConv!(G1!"martin") mConv;

        ex_d_to_python(delegate int(G1!"fred" g){ return g.i; });
        ex_d_to_python(function int(G1!"steve" g){ return g.i; });
        ex_d_to_python(new Conv());
        ex_d_to_python(&mConv);
        ex_d_to_python((G1!"john" a) => a.i);

        ex_python_to_d(delegate G1!"steve"(int i){ return new G1!"steve"(i); });
        ex_python_to_d(function G1!"fred"(int i){ return new G1!"fred"(i); });
        ex_python_to_d(new Conv2());
        ex_python_to_d((int a) => new G1!"martin"(a));
        ex_python_to_d((int a) => new G1!"john"(a));

        assert(py(new G1!"fred"(6)) == py(6));
        assert(py(new G1!"steve"(7)) == py(7));
        assert(py(new G1!"joe"(8)) == py(8));
        assert(py(new G1!"martin"(9)) == py(9));
        assert(py(new G1!"john"(10)) == py(10));

        assert(python_to_d!(G1!"fred")(d_to_python(20)) == new G1!"fred"(20));
        assert(python_to_d!(G1!"steve")(d_to_python(21)) == new G1!"steve"(21));
        assert(python_to_d!(G1!"joe")(d_to_python(22)) == new G1!"joe"(22));
        assert(python_to_d!(G1!"martin")(d_to_python(23)) == new G1!"martin"(23));
    }
}

unittest {
    auto func = function () {
        return 22;
    };

    assert(typeof(func).stringof != "int function()");
    auto py_func = py(func);
    assert(py_func().to_d!int() == 22);

    // but we'll convert typeof(func) back to int function()
    auto refunc = py_func.to_d!(int function())();
    assert(func is refunc);

    // as well as original type
    auto refunc2 = py_func.to_d!(typeof(func))();
    assert(func is refunc2);

    // or int function() pure
    auto refunc3 = py_func.to_d!(
            SetFunctionAttributes!(int function(), "D", 
                FunctionAttribute.pure_))();
    assert(func is refunc3);
    // or int function() nothrow
    auto refunc4 = py_func.to_d!(
            SetFunctionAttributes!(int function(), "D", 
                FunctionAttribute.nothrow_))();
    assert(func is refunc4);

    // etc

    auto dg = delegate() {
        return 42;
    };
    auto py_dg = py(dg);
    assert(py_dg().to_d!int() == 42);
}

unittest {
    import std.typecons;
    ex_python_to_d(delegate Tuple!(int, int) (PydObject obj) {
        return tuple(obj.a.to_d!int(), obj.b.to_d!int());
    });

    InterpContext context = new InterpContext();
    context.py_stmts("
        class Z:
            def __init__(self):
                self.a = 1
                self.b = 2
        foo = Z()
    ");
    auto result = context.foo.to_d!(Tuple!(int, int))();
}

unittest {
    import std.complex;
    ex_python_to_d(delegate Complex!(double) (PydObject obj) {
        return complex(obj.a.to_d!double(), obj.b.to_d!double());
    });

    InterpContext context = new InterpContext();
    context.py_stmts("
        class Z:
            def __init__(self):
                self.a = 1.5
                self.b = 2.5
        foo = Z()
    ");
    auto result = context.foo.to_d!(Complex!(double))();
}

unittest {
    import std.bigint;
    ex_python_to_d(delegate BigInt (PydObject obj) {
        return BigInt(obj.a.to_d!string());
    });

    InterpContext context = new InterpContext();
    context.py_stmts("
        class Z:
            def __init__(self):
                self.a = '12345'
        foo = Z()
    ");
    auto result = context.foo.to_d!BigInt();
}

unittest {
    import std.conv;
    ex_python_to_d(delegate double (PydObject obj) {
        return to!double(obj.a.to_d!string());
    });

    InterpContext context = new InterpContext();
    context.py_stmts("
        class Z:
            def __init__(self):
                self.a = '12345'
        foo = Z()
    ");
    auto result = context.foo.to_d!double();
}

unittest {
    ex_python_to_d(delegate bool (PydObject obj) {
        return obj.a.to_d!string() == "12345";
    });

    InterpContext context = new InterpContext();
    context.py_stmts("
        class Z:
            def __init__(self):
                self.a = '12345'
        foo = Z()
    ");
    auto result = context.foo.to_d!bool();
}

unittest {
    InterpContext context = new InterpContext();
    context.py_stmts("
        coo = 0
        foo = 1
        zoo = 2
    ");
    assert(context.coo.to_d!bool() == false);
    assert(context.foo.to_d!bool() == true);
    assert(context.zoo.to_d!bool() == true);
}

unittest {
    InterpContext context = new InterpContext();
    context.py_stmts("
        coo = 0.0
        foo = 1.0
        zoo = 0.1
        doo = 2.0
    ");
    assert(context.coo.to_d!bool() == false);
    assert(context.foo.to_d!bool() == true);
    assert(context.zoo.to_d!bool() == true);
    assert(context.doo.to_d!bool() == true);
}

unittest {
    InterpContext context = new InterpContext();
    context.py_stmts("
        fo = 1
        zo = 1.0
    ");
    assert(context.fo.to_d!double() == 1.0);
    assert(context.zo.to_d!double() == 1.0);
}

void main() {}
