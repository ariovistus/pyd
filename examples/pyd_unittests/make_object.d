import pyd.pyd, pyd.embedded;
import std.functional;
import std.range;
import std.algorithm;
import std.exception;
import python;
import std.stdio;

static this() {
    add_module("testing");
}

auto cantconvert(E)(lazy E e) {
    return collectException!PydConversionException(e);
}

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


unittest {
    import std.bigint;
    // python long -> BigInt
    assert(PyEval!BigInt("6 ** 603") == BigInt("6") ^^ 603);
    assert(PyEval!BigInt("-6 ** 603") == -BigInt("6") ^^ 603);
    // BigInt -> python long
    assert(py(BigInt("7") ^^ 47) == PyEval("7 ** 47"));
    assert(py(-BigInt("7") ^^ 47) == PyEval("-7 ** 47"));
}

unittest {
    PyStmts(q"{from array import array; a = array('i', [44,33,22,11]);}", "testing");
    assert(PyEval!(int[])("a", "testing") == [44,33,22,11]);
    assert(PyEval!(int[4])("a", "testing") == [44,33,22,11]);
}

// numpy unittests - numpy supports new buffer interface with PyBUF_ND,
// PyBUF_C_CONTIGUOUS, and PyBUF_F_CONTIGUOUS. handy for testing.
unittest {
    import std.stdio;

    PydObject numpy;
    try {
        numpy = py_import("numpy");
    }catch(PythonException e) {
        writeln("If you had numpy, we could do some more unittests");
    }

    if(numpy) {
        PyStmts(
                "from numpy import eye, ndarray\n"
                "a = eye(4,k=1)\n"
                "b = eye(3,4)\n"
                "f = ndarray(shape=[3,4], buffer=b, order='F')\n"
                ,
                "testing");
        assert(PyEval!(double[][])("a","testing") == 
                [[0, 1, 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1],
                 [0, 0, 0, 0]]);
        assert(PyEval!(double[4][4])("a","testing") == 
                [[0, 1, 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1],
                 [0, 0, 0, 0]]);
        assert(PyEval!(double[][4])("a","testing") == 
                [[0, 1, 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1],
                 [0, 0, 0, 0]]);
        assert(PyEval!(double[4][])("a","testing") == 
                [[0, 1, 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1],
                 [0, 0, 0, 0]]);
        assert(*PyEval!(double[4][4]*)("a","testing") == 
                [[0, 1, 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1],
                 [0, 0, 0, 0]]);
        assert(PyEval!(double[][])("b","testing") == 
                [[1, 0, 0, 0],
                 [0, 1, 0, 0],
                 [0, 0, 1, 0]]);
        assert(PyEval!(double[4][3])("b","testing") == 
                [[1, 0, 0, 0],
                 [0, 1, 0, 0],
                 [0, 0, 1, 0]]);
        assert(PyEval!(double[][3])("b","testing") == 
                [[1, 0, 0, 0],
                 [0, 1, 0, 0],
                 [0, 0, 1, 0]]);
        assert(PyEval!(double[4][])("b","testing") == 
                [[1, 0, 0, 0],
                 [0, 1, 0, 0],
                 [0, 0, 1, 0]]);
        assert(*PyEval!(double[4][3]*)("b","testing") == 
                [[1, 0, 0, 0],
                 [0, 1, 0, 0],
                 [0, 0, 1, 0]]);
        assert(PyEval!(double[][])("f","testing") == 
                [[1, 0, 0, 0],
                 [0, 0, 0, 1],
                 [0, 1, 0, 0]]);
        assert(PyEval!(double[4][3])("f","testing") == 
                [[1, 0, 0, 0],
                 [0, 0, 0, 1],
                 [0, 1, 0, 0]]);
        assert(PyEval!(double[][3])("f","testing") == 
                [[1, 0, 0, 0],
                 [0, 0, 0, 1],
                 [0, 1, 0, 0]]);
        assert(PyEval!(double[4][])("f","testing") == 
                [[1, 0, 0, 0],
                 [0, 0, 0, 1],
                 [0, 1, 0, 0]]);
        assert(*PyEval!(double[4][3]*)("f","testing") == 
                [[1, 0, 0, 0],
                 [0, 0, 0, 1],
                 [0, 1, 0, 0]]);

        assert(PyEval("f","testing").bufferview().format == "d");
        // this won't work because f is a matrix of doubles
        assert(cantconvert(PyEval!(float[][])("f","testing")));
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
}

// bytearray tests - bytearray supports the new buffer interface with
// PyBUF_ND and PyBUF_C_CONTIGUOUS
unittest {
    PyStmts(
            "a = bytearray('abcdefg')\n"
            ,
            "testing");
    auto a = PyEval("a","testing");
    auto b = a.bufferview();
    assert(PyEval!(ubyte[])("a", "testing") == cast(ubyte[]) "abcdefg");
    PyObject* a_ptr = Py_INCREF(a.ptr);
    scope(exit) Py_DECREF(a_ptr);
    // d_type should be calling this function
    assert(d_type_buffer!(ubyte[])(a_ptr) == cast(ubyte[]) "abcdefg");
    // bytearray's elements are unsigned
    assert(cantconvert(d_type_buffer!(byte[])(a_ptr)));
    // with char[], d_type probably isn't calling this function, but anyways
    // char[]'s element type is dchar. Go figure.
    assert(cantconvert(d_type_buffer!(char[])(a_ptr)));
}

unittest {
    assert(d_type!int(_py(15)) == 15);
    assert(d_type!float(_py(1.0f)) == 1.0f);
    import std.complex;
    assert(d_type!(Complex!double)(_py(complex(2.0,3.0))) == complex(2.0,3.0));
    import std.typecons;
    assert(d_type!(Tuple!(int,double))(_py(tuple(2,3.0))) == tuple(2,3.0));
    assert(d_type!(Tuple!(int, "a",double, "b"))(_py(Tuple!(int, "a", double, "b")(2,3.0))) == Tuple!(int,"a",double,"b")(2,3.0));
}

unittest {
    assert(PyEval!byte("int(30)") == 30);
    assert(PyEval!byte("long(30)") == 30);
    assert(PyEval!byte(format("int(%s)", byte.max)) == byte.max);
    assert(PyEval!byte(format("int(%s)", byte.min)) == byte.min);
    assert(PyEval!byte(format("long(%s)", byte.max)) == byte.max);
    assert(PyEval!byte(format("long(%s)", byte.min)) == byte.min);
    assert(PyEval!ubyte("int(30)") == 30);
    assert(PyEval!ubyte("long(30)") == 30);
    assert(PyEval!ubyte(format("int(%s)", ubyte.max)) == ubyte.max);
    assert(PyEval!ubyte(format("int(%s)", ubyte.min)) == ubyte.min);
    assert(PyEval!ubyte(format("long(%s)", ubyte.max)) == ubyte.max);
    assert(PyEval!ubyte(format("long(%s)", ubyte.min)) == ubyte.min);
    assert(PyEval!short("int(30)") == 30);
    assert(PyEval!short("long(30)") == 30);
    assert(PyEval!ushort("int(30)") == 30);
    assert(PyEval!ushort("long(30)") == 30);
    assert(PyEval!int("int(300)") == 300);
    assert(PyEval!int("long(300)") == 300);
    assert(PyEval!uint("int(300)") == 300);
    assert(PyEval!uint("long(300)") == 300);
    assert(PyEval!long("int(30)") == 30);
    assert(PyEval!long("long(30)") == 30);
    assert(PyEval!ulong("int(30)") == 30);
    assert(PyEval!ulong("long(30)") == 30);
    assert(PyEval!long(format("long(%s)", long.max)) == long.max);
    assert(PyEval!long(format("long(%s)", long.min)) == long.min);
    assert(PyEval!ulong(format("long(%s)", ulong.max)) == ulong.max);

    // values out of bounds are out of bounds.

    assert(cantconvert(PyEval!byte("int(300)")));
    assert(cantconvert(PyEval!ubyte("int(300)")));
    assert(cantconvert(PyEval!ubyte("int(-1)")));

    assert(py(cast(byte)1) == py(1));
}

unittest {
    assert(PyEval!(int[])("[4,5,7]") == [4,5,7]);
    assert(PyEval!(int[3])("[4,5,7]") == [4,5,7]);
    assert(PyEval!(immutable(int)[])("[4,5,7]") == [4,5,7]);
    assert(PyEval!(immutable(int)[3])("[4,5,7]") == [4,5,7]);
    assert(PyEval!(immutable(int[]))("[4,5,7]") == [4,5,7]);
    assert(PyEval!(immutable(int[3]))("[4,5,7]") == [4,5,7]);
}

unittest {
    assert(equal(PyEval!(PydInputRange!int)("[5,6,7,8]"), [5,6,7,8]));
    assert(equal(PyEval!(PydInputRange!int)("xrange(2, 20)"), iota(2,20)));
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
    alias unaryFun!"a.i" uConv;
    alias uConv!(G1!"martin") mConv;

    d_to_python(delegate int(G1!"fred" g){ return g.i; });
    d_to_python(function int(G1!"steve" g){ return g.i; });
    d_to_python(new Conv());
    d_to_python(&mConv);
    d_to_python((G1!"john" a) => a.i);

    python_to_d(delegate G1!"steve"(int i){ return new G1!"steve"(i); });
    python_to_d(function G1!"fred"(int i){ return new G1!"fred"(i); });
    python_to_d(new Conv2());
    python_to_d((int a) => new G1!"martin"(a));
    python_to_d((int a) => new G1!"john"(a));

    assert(py(new G1!"fred"(6)) == py(6));
    assert(py(new G1!"steve"(7)) == py(7));
    assert(py(new G1!"joe"(8)) == py(8));
    assert(py(new G1!"martin"(9)) == py(9));
    assert(py(new G1!"john"(10)) == py(10));

    assert(d_type!(G1!"fred")(_py(20)) == new G1!"fred"(20));
    assert(d_type!(G1!"steve")(_py(21)) == new G1!"steve"(21));
    assert(d_type!(G1!"joe")(_py(22)) == new G1!"joe"(22));
    assert(d_type!(G1!"martin")(_py(23)) == new G1!"martin"(23));
}

void main() {}
