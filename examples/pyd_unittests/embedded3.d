import pyd.pyd, pyd.embedded;

static this() {
    on_py_init({
    add_module!(ModuleName!"testing")();
    });
    py_init();
}
// py_def
unittest {
    alias py_def!(
            "def func1(a):\n"
            " return a*2+1",
            "testing", 
            int function(int)) func1;
    assert(func1(1) == 3);    
    assert(func1(2) == 5);    
    assert(func1(3) == 7);    
}

unittest {
    // py_stmts with modulename executes within that module

    py_stmts(
            "a = \"doctor!\""
            ,
            "testing");
    py_stmts(
            "import testing\n"
            "assert testing.a == \"doctor!\""
            );

    // however, py_stmts contextualized or without modulename does not.

    py_stmts(
            "import testing\n"
            "a = \"nurse!\""
            );
    py_stmts(
            "import testing\n"
            "assert testing.a == \"doctor!\""
            );
    InterpContext c = new InterpContext();
    c.py_stmts(
            "import testing\n"
            "a = \"nurse!\""
            );
    py_stmts(
            "import testing\n"
            "assert testing.a == \"doctor!\""
            );

}

void main() {}
