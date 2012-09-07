import pyd.pyd, pyd.embedded;
import std.range;
import std.algorithm;
import std.exception;
import python;
import std.stdio;

static this() {
    add_module("testing");
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

    auto cantconvert(E)(lazy E e) {
        return collectException!PydConversionException(e);
    }
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

void main() {}
