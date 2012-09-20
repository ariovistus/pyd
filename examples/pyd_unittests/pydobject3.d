import pyd.pyd, pyd.embedded;

static this() {
    on_py_init({
    add_module!(ModuleName!"testing")();
    });
    py_init();
}

// PydObject as dict
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
    g.del_item("b");
    assert((g.items()).toString() == "[('a', 'b')]");
    auto g2 = g.copy();
    assert((g2.items()).toString() == "[('a', 'b')]");
    g2.del_item("a");
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
    assert(g.has_key("k"));
    assert(g.has_key("a"));

    g = py([5:7, 8:10]);
    g.clear();
    assert(g.length() == 0);
}

// PydObject as list
unittest {
    auto g = py(["a","b","c","e"]);
    assert(py("a") in g);
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

// PydObject as number (int? long? who know?)
unittest {
    auto n = py(1);
    n = n + py(2);
    assert(n == py(3));
    assert(py(2) + 1 == py(3));
    n = n * py(12);
    assert(n == py(36));
    n = n / py(5);
    assert(n == py(7.2));
    n = py(36).floor_div(py(5));
    assert(n == py(7));
    n = py(36).true_div(py(5));
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
    assert(n == py(14./3)); // 4.6bar
    assert(n.as_long() == py(4));
    n = py(4);
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

// PydObject as python object
unittest {
    py_stmts(q"<class X:
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
            >", "testing");
    auto x = py_eval("X()","testing");
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

// Buffer interface
version(Python_2_6_Or_Later) {
    unittest {
        auto arr = py_eval("bytearray([1,2,3])");
        auto b = arr.buffer_view();
        import std.stdio;
        assert(b.format == "B");
        assert(b.itemsize == 1);
        if(b.has_simple) {
            assert(b.buf == [1,2,3]);
        }
        if(b.has_nd) {
            assert(b.ndim == 1);
            assert(b.shape == [3]);

        }
        if(b.has_strides) {
            assert(b.strides == [1]);
        }
        if(b.has_indirect) {
            assert(b.suboffsets == []);
        }
    }

    unittest {
        import std.stdio;

        PydObject numpy;
        try {
            numpy = py_import("numpy");
        }catch(PythonException e) {
            writeln("If you had numpy, we could do some more unittests");
        }

        if(numpy) {
            py_stmts(
                    "from numpy import eye\n"
                    "a = eye(4,k=1)\n"
                    ,
                    "testing");
            PydObject ao = py_eval("a","testing");
            auto b = ao.buffer_view();
            assert(b.format == "d");
            assert(b.itemsize == 8);
            assert(b.has_nd);
            assert(b.ndim == 2);
            assert(b.c_contiguous);
            assert(b.shape == [4,4]);
            assert(b.strides == [32, 8]);
            assert(b.suboffsets == []);
            // ao is
            // 0 1 0 0
            // 0 0 1 0
            // 0 0 0 1
            // 0 0 0 0
            assert(b.item!double(1,0) == 0);
            assert(b.item!double(0,1) == 1);
        }
    }
}

void main(){}
