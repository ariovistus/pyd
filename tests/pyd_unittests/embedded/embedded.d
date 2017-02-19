import pyd.pyd, pyd.embedded;
import deimos.python.Python;

import std.exception;
import std.stdio;

static this() {
    on_py_init({
    add_module!(ModuleName!"testing")();
    });
    py_init();
}
// py_def
unittest {
    alias py_def!(
            "def func1(a):
             return a*2+1
            ",
            "testing",
            int function(int)) func1;
    assert(func1(1) == 3);
    assert(func1(2) == 5);
    assert(func1(3) == 7);
}

version(Python_3_0_Or_Later) {
}else{
    // py_stmts
    unittest {
        // futures do not persist across py_stmts calls
        py_stmts(
                "a = 3 / 4;"
                ,
                "testing");
        assert(py_eval!double("a", "testing") == 0);
        py_stmts("
                from __future__ import division
                b = 3 / 4;"
                ,
                "testing");
        assert(py_eval!double("b", "testing") == 0.75);
        py_stmts(
                "a = 3 / 4;"
                ,
                "testing");
        assert(py_eval!double("a", "testing") == 0);

        // but they do across contextual py_stmts calls.
        InterpContext c = new InterpContext();
        c.py_stmts("
                import testing
                a = 3 / 4;"
                );
        assert(c.py_eval!double("a") == 0);
        c.py_stmts("
                from __future__ import division
                b = 3 / 4;"
                );
        assert(c.py_eval!double("b") == 0.75);
        c.py_stmts(
                "a = 3 / 4;"
                );
        assert(c.py_eval!double("a") == 0.75);
    }
}
unittest {
    // py_stmts with modulename executes within that module

    py_stmts(
            "a = \"doctor!\""
            ,
            "testing");
    py_stmts("
            import testing
            assert testing.a == \"doctor!\""
            );

    // however, py_stmts contextualized or without modulename does not.

    py_stmts("
            import testing
            a = \"nurse!\""
            );
    py_stmts("
            import testing
            assert testing.a == \"doctor!\""
            );
    InterpContext c = new InterpContext();
    c.py_stmts("
            import testing
            a = \"nurse!\""
            );
    py_stmts("
            import testing
            assert testing.a == \"doctor!\""
            );
}

unittest {
    InterpContext c = new InterpContext();
    c.locals["i"] = py(1);
    c.j = py(2);
    c.k = 4;
    c.py_stmts("
        assert i == 1;
        assert j == 2;
        assert k == 4"
        );
   // (*^&^&* broken @property
   // static assert(is(typeof(c.unicode("abc")) == PydObject));
}

unittest {
    auto ex = collectException!PythonException(py_eval("import sys"));
    auto msg = ex.py_message;
    assert(ex.py_message == "invalid syntax", ex.py_message);

}
unittest {
    InterpContext c = new InterpContext();
    auto ex = collectException!PythonException(c.py_eval("import sys"));
    assert(ex.py_message == "invalid syntax");
    assert(ex.traceback() == null);
}

unittest {
    auto ex = collectException!PythonException(py_stmts("&raise Exception('foo')"));
    assert(ex.py_message == "invalid syntax");
    assert(ex.traceback() == null);
}
unittest {
    auto ex = collectException!PythonException(py_stmts("raise Exception('foo')"));
    assert(ex.py_message == "foo");
    assert(ex.traceback() != null);
}
unittest {
    auto ex = collectException!PythonException(py_eval("import sys"));
    assert(ex.py_message == "invalid syntax");
    assert(ex.traceback() == null);
}

unittest {
    auto inspect = py_import("inspect");
    auto ex = collectException!PythonException(inspect.currentframe.opCall());
    assert(ex.py_message == "call stack is not deep enough");
}
unittest {
    auto c = new InterpContext();
    c.py_stmts("import inspect");
    auto ex = collectException!PythonException(c.inspect.currentframe.opCall());
    assert(ex.py_message == "call stack is not deep enough");
}
unittest {
    auto c = new InterpContext();
    c.pushDummyFrame();
    c.py_stmts("import inspect");
    auto frame = c.inspect.currentframe.opCall();
}


void main() {}
