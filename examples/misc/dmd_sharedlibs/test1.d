import std.stdio;

static this() {
    writeln("yawn. stretch.");
}
static ~this() {
    writeln("yawn. zzzzz");
}

unittest {
    writeln("lets test this donut.");
}

extern(C) int foo(int i) {
    return cast(int)("abc".dup.length) + i+1;
}

