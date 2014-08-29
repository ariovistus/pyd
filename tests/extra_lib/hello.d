// Hello World, using imports from other directories
import pyd.pyd;
import foo;
import bar;

void hello()
{
    foo.foo();
    bar.bar();
}

extern(C) void PydMain() {
    def!(hello)();
    module_init();
}
