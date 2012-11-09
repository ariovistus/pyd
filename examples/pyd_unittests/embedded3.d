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

unittest {
    InterpContext c = new InterpContext();
    c.locals["i"] = py(1);
    c.j = py(2);
    c.k = 4;
    c.py_stmts(
        "assert i == 1;"
        "assert j == 2;"
        "assert k == 4"
        );
   // (*^&^&* broken @property
   // static assert(is(typeof(c.unicode("abc")) == PydObject));
}

void main() {}
