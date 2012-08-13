module pyind;

import std.stdio;
import pyd.pyd;
import pyd.embedded;
import python: Py_Initialize;


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
    def!("office", knock)("a brain specialist works here"); 
    add_module("office");
    wrap_class!(Y, 
        Def!(Y.query),
        Property!(Y.brain_status),
        Property!(Y.resolution, true),
    )("","office");
    ErrInterceptor.wrap_class("office");
    ErrInterceptor.replaceStderr();
}

void main() {
    // simple expressions can be evaluated
    int i = PyEval!int("1+2", "office");
    writeln(i);

    // functions can be defined in D and invoked in Python (see above)
    PyStmts(q"<
knock()
>", "office");

    // functions can be defined in Python and invoked in D
    alias PyDef!("def holler(a): 
            return ' '.join(['Doctor!']*a)","office", string, int) call_out;
    writeln(call_out(1));
    writeln(call_out(5));

    // classes can be defined in D and used in Python

    auto y = PyEval("Y()","office");
    y.method("query");

    // classes can be defined in Python and used in D
    PyStmts(q"<
class X:
    def __init__(self):
        self.resolution = "NO!"
    def what(self):
        return "Yes, yes I am!"
        >", "office");
    auto x = PyEval("X()","office");
    writeln(x.resolution);
    writeln(x.method("what"));

    // properties totally work

    PyStmts(q"<
y = Y();
y.brain_status = "HURTS";
print "MY BRAIN %s" % y.brain_status;
print y.resolution
>","office");
}

unittest {
    assert(d_type!int(_py(15)) == 15);
    assert(d_type!float(_py(1.0f)) == 1.0f);
    import std.complex;
    assert(d_type!(Complex!double)(_py(complex(2.0,3.0))) == complex(2.0,3.0));
    import std.typecons;
    assert(d_type!(Tuple!(int,double))(_py(tuple(2,3.0))) == tuple(2,3.0));
    assert(d_type!(Tuple!(int, "a",double, "b"))(_py(Tuple!(int, "a", double, "b")(2,3.0))) == Tuple!(int,"a",double,"b")(2,3.0));
}
unittest {
    alias PyDef!(q"<def func1(a): 
            return a*2+1>","office", int, int) func1;
    assert(func1(1) == 3);    
    assert(func1(2) == 5);    
    assert(func1(3) == 7);    
}

unittest {
    auto g = py(["a":"b"]);
    assert((g.keys()).toString() == "['a']");
    assert((g.values()).toString() == "['b']");
    assert(g.items().toString() == "[('a', 'b')]");
    assert(g["a"].toString()  == "b");
    g["b"] = py("truck");
    assert(g.items().toString() == "[('a', 'b'), ('b', 'truck')]" ||
            g.items().toString() == "[('b', 'truck'), ('a', 'b')]");
    foreach(key, val; g) {
        if (key.toString() == "a") assert(val.toString() == "b");
        else if (key.toString() == "b") assert(val.toString() == "truck");
        else assert(false);
    }
    g.delItem("b");
    assert((g.items()).toString() == "[('a', 'b')]");
    auto g2 = g.copy();
    assert((g2.items()).toString() == "[('a', 'b')]");
    g2.delItem("a");
    assert((g2.items()).toString() == "[]");
    assert((g.items()).toString() == "[('a', 'b')]");
    g2 = py(["k":"z", "a":"f"]);
    g.merge(g2);
    assert(g.items().toString() == "[('k', 'z'), ('a', 'f')]" ||
            g.items().toString() == "[('a', 'f'), ('k', 'z')]");
    g = py(["a":"b"]);
    g.merge(g2,false);
    assert(g.items().toString() == "[('k', 'z'), ('a', 'b')]" ||
            g.items().toString() == "[('a', 'b'), ('k', 'z')]");
    assert("k" in g);
    assert("a" in g);
    assert(g.hasKey("k"));
    assert(g.hasKey("a"));
}

unittest {
    auto g = py(["a","b","c","e"]);
    assert("a" in g);
    assert("e" in g);
    foreach(i,x; g) {
        if(i == py(0)) assert(x == py("a"));
        if(i == py(1)) assert(x == py("b"));
        if(i == py(2)) assert(x == py("c"));
        if(i == py(3)) assert(x == py("e"));
    }
    {
        int i = 0;
        foreach(x; g) {
            if(i == (0)) assert(x == py("a"));
            if(i == (1)) assert(x == py("b"));
            if(i == (2)) assert(x == py("c"));
            if(i == (3)) assert(x == py("e"));
            i++;
        }
    }
    auto g2 = g ~ py(["a","c","e"]);
    assert(g2 == py(["a","b","c","e","a","c","e"]));
    g ~= py(["a","c","e"]);
    assert(g == py(["a","b","c","e","a","c","e"]));
    //writeln(g.count(py(["c","e"])));
    assert(g.count(py("c")) == 2);
    assert(g.index(py("b")) == 1);
    g.insert(3, py("X"));
    assert(g == py(["a","b","c","X","e","a","c","e"]));
    g.append(py("Z"));
    assert(g == py(["a","b","c","X","e","a","c","e", "Z"]));
    g.sort();
    assert(g == py(["X","Z","a","a","b","c","c","e","e"]));
    g.reverse();
    assert(g == py(["e","e","c","c","b","a","a","Z","X"]));
    g = py(["a","b"]);
    assert(g * 2 == py(["a","b","a","b"]));
    g *= 2;
    assert(g == py(["a","b","a","b"]));
    g = py(["a","b"]);
    assert(g ~ ["z"] == py(["a","b","z"]));
    assert(g ~ py(["z"]) == py(["a","b","z"]));
    g ~= py(["f","h"]);
    assert(g == py(["a","b","f","h"]));
}

unittest {
    auto n = py(1);
    n = n + py(2);
    assert(n == py(3));
    assert(py(2) + 1 == py(3));
    n = n * py(12);
    assert(n == py(36));
    n = n / py(5);
    assert(n == py(7));
    n = py(36).floorDiv(py(5));
    assert(n == py(7));
    n = py(36).trueDiv(py(5));
    assert(n == py(7.2)); // *twitch*
    n = (py(37).divmod(py(5)));
    assert(n.toString() == "(7, 2)" || n.toString() == "(7L, 2L)");
    n = py(37) % py(5);
    assert(n == py(2));
    n = py(3) ^^ py(4);
    assert(n == py(81));
    // holy guacamole! I didn't know Python's pow() did this!
    n = py(13).pow(py(3), py(5));
    assert(n == (py(13) ^^ py(3)) % py(5));
    assert(n == py(2));
    assert(py(1).abs() == py(1));
    assert(py(-1).abs() == py(1));
    assert(~py(2) == py(-3));
    assert((py(15) >> py(3)) == py(1));
    assert(py(1) << py(3) == py(8));
    assert((py(7) & py(5)) == py(5));
    assert((py(17) | py(5)) == py(21));
    assert((py(17) ^ py(5)) == py(20));

    n = py(1);
    n += py(3);
    assert(n == py(4));
    n -= py(2);
    assert(n == py(2));
    n *= py(7);
    assert(n == py(14));
    n /= py(3);
    assert(n == py(4));
    n %= py(3);
    assert(n == py(1));
    n <<= py(4);
    assert(n == py(16));
    n >>= py(1);
    assert(n == py(8));
    n |= py(17);
    assert(n == py(25));
    n &= py(19);
    assert(n == py(17));
    n ^= py(11);
    assert(n == py(26));
}

unittest {
    PyStmts(q"<class X:
        def __init__(self):
            self.a = "widget"
            self.b = 515
        def __add__(self, g):
            return self.b + g;
        def __getitem__(self, i):
            return 1000 + i*2
        def __setitem__(self, i, j):
            self.b = 100*j + 10*i;
        def foo(self):
            return self.a
        def bar(self, wongo, xx):
            return "%s %s b %s" % (self.a, wongo, self.b)
            >", "office");
    auto x = PyEval("X()","office");
    assert(x.getattr("a") == py("widget"));
    assert(x.a == py("widget"));
    assert(x.method("foo") == py("widget"));
    assert(x[4] == py(1008));
    auto xb = x.b;
    x[4] = 5;
    assert(x.b == py(540));
    x.b = xb;
    // *#^$&%#*(@*&$!!!!!
    // I long for the day..
    //assert(x.foo != x.foo());
    //assert(x.foo() == py("widget"));
    assert(x.foo.opCall() == py("widget"));
    assert(x.bar(py(9.5),1) == py("widget 9.5 b 515"));
    assert(x.bar(9.5,1) == py("widget 9.5 b 515"));
    assert(x + 10 == py(525));
}
