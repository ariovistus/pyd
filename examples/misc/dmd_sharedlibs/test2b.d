import std.stdio;

static this() {
    writeln("yawn yawn. stretch stretch.");
}

extern(C) int foo2(int i) {
    return cast(int)("abcd".dup.length) + i+1;
}
