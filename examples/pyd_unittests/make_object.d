import pyd.pyd, pyd.embedded;

static this() {
    add_module("testing");
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

void main() {}
