import std.string;

extern(C) {
    struct Foobar {
        int i;
        int j;
        double d;
    }
    __gshared Foobar foo;
}

void main() {
    import std.stdio;
    assert(foo.i == 1, format("foo.i=%s vs 1", foo.i));
    assert(foo.j == 2, format("foo.j=%s vs 2", foo.j));
    assert(foo.d == 3.4, format("foo.j=%s vs 3.4", foo.j));
}
