// A minimal "hello world" Pyd module.
module hello2;

import pyd.pyd;
import std.stdio;

void hello() {
    writefln("Hello, burrito!");
}

extern(C) void PydMain() {
    def!(hello)();
    module_init();
}
