import pyd.pyd, pyd.embedded, pyd.extra;
import deimos.python.Python;
import std.complex;
import std.bigint;
import std.string;

static this() {
    py_init();
}

/*
unittest {
    alias cfloat_ = Complex!float;
    
    cfloat_[] data = [
        cfloat_(1,2),
        cfloat_(1,3),
        cfloat_(1,4),
        cfloat_(1,6),
    ];

    auto npa = d_to_python_numpy_ndarray(data);
    auto npop = new PydObject(npa);
    assert(npop[0].imag.to_d!float() == 2);
    assert(npop[0].getattr("real").to_d!float() == 1);

    foreach(i, datum; data) {
        assert(npop[i].imag.to_d!float() == datum.im);
        assert(npop[i].getattr("real").to_d!float() == datum.re);
    }
}
*/

// should convert numpy number types to primitives
unittest {
    auto context = new InterpContext();
    context.py_stmts("
        import numpy
        b = numpy.bool_()
        i8 = numpy.int8()
        i16 = numpy.int16()
        i32 = numpy.int32()
        i64 = numpy.int64()
        u8 = numpy.uint8()
        u16 = numpy.uint16()
        u32 = numpy.uint32()
        u64 = numpy.uint64()
        f32 = numpy.float32()
        f64 = numpy.float64()
        c64 = numpy.complex64()
    ");

    context.b.to_d!bool();
    foreach(var; ["b", "i8", "i16", "i32", "i64", "u8", "u16", "u32", "u64"]) {
        context.locals[var].to_d!byte();
        context.locals[var].to_d!ubyte();
        context.locals[var].to_d!short();
        context.locals[var].to_d!ushort();
        context.locals[var].to_d!int();
        context.locals[var].to_d!uint();
        context.locals[var].to_d!long();
        context.locals[var].to_d!ulong();
        context.locals[var].to_d!BigInt();
    }
    foreach(var; ["f32", "f64"]) {
        context.locals[var].to_d!float();
        context.locals[var].to_d!double();
        context.locals[var].to_d!real();
    }

    context.c64.to_d!(Complex!float)();

    context.py_stmts("
        b = numpy.bool_(True)
        i8 = numpy.int8(5)
        i16 = numpy.int16(17)
        i64 = numpy.int64(-11)
        u32 = numpy.uint32(20)
        f32 = numpy.float32(7.5)
    ");
    assert(context.b.to_d!bool() == true);
    assert(context.b.to_d!int() == 1);
    assert(context.i8.to_d!byte() == 5);
    assert(context.i8.to_d!ushort() == 5);
    assert(context.i8.to_d!long() == 5);
    assert(context.i8.to_d!float() == 5);
    assert(context.i8.to_d!BigInt() == 5);
    assert(context.i16.to_d!byte() == 17);
    assert(context.i16.to_d!ushort() == 17);
    assert(context.i16.to_d!long() == 17);
    assert(context.i16.to_d!float() == 17);
    assert(context.i16.to_d!BigInt() == 17);
    assert(context.i64.to_d!byte() == -11);
    assert(context.i64.to_d!long() == -11);
    assert(context.i64.to_d!BigInt() == -11);
    assert(context.u32.to_d!int() == 20);
    assert(context.f32.to_d!int() == 7);
    assert(context.f32.to_d!float() == 7.5);
    assert(context.f32.to_d!double() == 7.5);
    assert(context.f32.to_d!BigInt() == 7);
}

unittest {
    alias cfloat_ = const(Complex!float);
    
    cfloat_[] data = [
        cfloat_(1,2),
        cfloat_(1,3),
        cfloat_(1,4),
        cfloat_(1,6),
    ];

    auto npa = d_to_python_numpy_ndarray(data);
    auto npop = new PydObject(npa);
    assert(npop[0].imag.to_d!float() == 2);
    assert(npop[0].getattr("real").to_d!float() == 1);

    foreach(i, datum; data) {
        assert(npop[i].imag.to_d!float() == datum.im);
        assert(npop[i].getattr("real").to_d!float() == datum.re);
    }
}

unittest {
    bool[] data = [true, false, true, true, false];
    auto npa = new PydObject(d_to_python_numpy_ndarray(data));
    foreach(i, datum; data) {
        assert(npa[i].to_d!bool() == datum);

    }
}

unittest {
    InterpContext context = new InterpContext();

    context.py_stmts(outdent("
        import numpy
        a = numpy.eye(2, dtype='complex64')
    "));

    context.a.to_d!(Complex!float[][] )();
}

unittest {
    InterpContext context = new InterpContext();

    context.py_stmts(outdent("
        import numpy
        a = numpy.eye(2, dtype='complex128')
    "));

    context.a.to_d!(Complex!double[][] )();
}

void main() {}
