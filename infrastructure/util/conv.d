module util.conv;

import std.string;

char* zc()(string s) {
    if(s.length && s[$-1] == 0) return s.dup.ptr;
    return ((cast(char[])s) ~ "\0").ptr;
}


immutable(char)* zcc()(const(char)[] s) pure nothrow {
    return toStringz(s);
}

