// stuff in our library

static this() {
    import std.c.stdio;
    printf("yawn. stretch.\n");
}

static ~this() {
    import std.c.stdio;
    printf("yawn. zzz.\n");
}

extern(C) int foo(int i) {
    return i+1;
}
unittest {
    import std.stdio;
    writeln("lets test this mannekin");
}

