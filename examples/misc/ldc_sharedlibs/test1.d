// stuff in our library

static this() {
    import std.c.stdio;
    printf("yawn. stretch.");
}

extern(C) int foo(int i) {
    return i+1;
}

