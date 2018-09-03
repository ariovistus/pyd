// stuff in our library

static this() {
    import std.stdio;
    writeln("yawn. stretch.");
}

unittest {
    import std.stdio;
    writeln("running a unittest");
}

extern(C) int foo(int i) {
	auto a = new char[1];
    return i+1;
}

