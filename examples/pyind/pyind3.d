module pyind;

import std.stdio;
import pyd.pyd;
import deimos.python.pyport;
import pyd.embedded;


void knock() {
    writeln("knock! knock! knock!");
    writeln("BAM! BAM! BAM!");
}

class Y {
    void query() {
        writeln("Are you a BRAIN SPECIALIST?");
    }

    string _status;
    void brain_status(string s) {
        _status = s;
    }
    string brain_status() {
        return _status;
    }

    string resolution() {
        return "Well, let's have a look at it, shall we Mr. Gumby?";
    }
}


static this() {
    on_py_init({
            def!(knock, ModuleName!"office", 
                Docstring!"a brain specialist works here")(); 
            add_module!(ModuleName!"office")();
    });

    on_py_init({
    wrap_class!(Y, 
        Def!(Y.query),
        ModuleName!"office",
        Property!(Y.brain_status),
        Property!(Y.resolution, Mode!"r"),
    )();
    }, PyInitOrdering.After);

    py_init();
}

void main() {
    // simple expressions can be evaluated
    int i = py_eval!int("1+2", "office");
    writeln(i);

    // functions can be defined in D and invoked in Python (see above)
    py_stmts(q"<
knock()
>", "office");

    // functions can be defined in Python and invoked in D
    alias py_def!("def holler(a): 
            return ' '.join(['Doctor!']*a)","office", 
            string function(int)) call_out;
    writeln(call_out(1));
    writeln(call_out(5));

    // classes can be defined in D and used in Python

    auto y = py_eval("Y()","office");
    y.method("query");

    // classes can be defined in Python and used in D
    py_stmts(q"<
class X:
    def __init__(self):
        self.resolution = "NO!"
    def what(self):
        return "Yes, yes I am!"
        >", "office");
    auto x = py_eval("X()","office");
    writeln(x.resolution);
    writeln(x.method("what"));

    // properties totally work

    py_stmts(q"<
y = Y();
y.brain_status = "HURTS";
print("MY BRAIN %s" % y.brain_status);
print(y.resolution)
>","office");
}




