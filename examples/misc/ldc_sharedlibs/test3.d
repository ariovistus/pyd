
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
    writeln(foo.i);
    writeln(foo.j);
    writeln(foo.d);
}
