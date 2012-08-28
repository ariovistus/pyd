module util.conv;

import std.string: toStringz;

char* zc(string s) {
    if(s.length && s[$-1] == 0) return s.dup.ptr;
    return ((cast(char[])s) ~ "\0").ptr;
}

alias toStringz zcc;
