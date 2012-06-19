module pyind;

/++
 + Things we want to do:
 +  * run python code in D (easily) [check]
 +  * run D code in python [?]
 +  * declare python functions and use them in D [check]
 +  * access and manipulate python globals in D [check]
 +  * wrap D classes/structs and use them in python or D [check]
 +  * use python class instances in D [why?]
 +  * wrap D ranges and iterators or whatever and iterate through them in python [why?]
 +  * wrap python iterators as D input ranges [why?]
 +  * do things with inheritance [why??!??]
 +/  
import std.algorithm: findSplit;
import std.string: strip;
import std.stdio;
import pyd.pyd;
import python;

/++
 + PyErr_Print() prints error messages to stderr.
 + But I want it in the message in a string so I can stuff it in an Exception.
 + So here is glue. The type gets wrapped and an instance is assigned to 
 + sys.stderr. Then sys.stderr gets unwrapped and we manipulate it within D.
 + Cute? (yeah, we could just use StringIO) (or handle_exception)
 +/
class ErrInterceptor {
    string _msg;
    void write(string s) {
        writefln("gotted: %s",s);
        _msg ~= s;
    }
    void clear() {
        _msg = "";
    }
    string msg(){
        return _msg;
    }
}

PydObject py_import(string name) {
    return new PydObject(PyImport_ImportModule(zcc(name)));
}

void run_tacotruck() {
    writeln("choof choof choof");
}

static this() {
    Py_Initialize();
    add_module("d_pydef");
    def!("tacotruck", run_tacotruck)("running taco trucks is important"); 
    add_module("tacotruck");
    auto m = py_import("tacotruck");
    wrap_class!(ErrInterceptor, 
            Def!(ErrInterceptor.write),
            Def!(ErrInterceptor.clear),
            Def!(ErrInterceptor.msg))(
            "taco trucks are repositories for tasty mexican food", // docstring
            "tacotruck"); // module name
    auto sys = py_import("sys");
    auto old_stderr = sys.getattr("stderr");
    sys.setattr("stderr", py(new ErrInterceptor()));
}

string interceptStderr() {
    auto z = PyErr_Occurred();
    if(!z) {
        return "";
    }
    string errmsg;
    PyErr_Print();
    writeln(new PydObject(z));
    auto stderr = py_import("sys").getattr("stderr");
    auto msg = stderr.method("msg");
    if(msg != new PydObject() /*None*/) {
        errmsg = msg.toDItem!string();
    }
    PyErr_Clear();
    stderr.method("clear");
    return errmsg;
}

/++
 + Take a python function and wrap it so we can call it from D!
 + Note that type is really the only thing that need be static here, but hey.
 + We are stuffing the function in module d_pydef. Could probably go elsewhere.
 +/
R PyDef(string python, R, Args...)(Args args) {
    enum afterdef = findSplit(python, "def")[2];
    enum ereparen = findSplit(afterdef, "(")[0];
    enum name = strip(ereparen) ~ "\0";
    static PydObject m, func, locals; 
    static Exception exc;
    static string errmsg;
    static bool once = true;
    if(once) {
        once = false;
        m = py_import("d_pydef");
        locals = m.getdict();
        if("__builtins__" !in locals) {
            auto builtins = new PydObject(PyEval_GetBuiltins());
            locals["__builtins__"] = builtins;
        }
        auto pres = PyRun_String(
                    zcc(python), 
                    Py_file_input, locals.ptr, locals.ptr);
        if(pres) {
            auto res = new PydObject(pres);
            func = m.getattr(name);
        }else{
            errmsg = interceptStderr();
        }
    }
    if(!func) {
        throw new Exception(errmsg);
    }
    return func(args).toDItem!R();
}

T PyEval(T = PydObject)(string python) {
    auto m = py_import("d_pydef");
    auto locals = m.getdict();
    if("__builtins__" !in locals) {
        auto builtins = new PydObject(PyEval_GetBuiltins());
        locals["__builtins__"] = builtins;
    }
    auto pres = PyRun_String(
            zcc(python), 
            Py_eval_input, locals.ptr, locals.ptr);
    if(pres) {
        auto res = new PydObject(pres);
        return d_type!T(res.ptr);
    }else{
        throw new Exception(interceptStderr());
    }
}

void PyStmts(string python) {
    auto m = py_import("d_pydef");
    auto locals = m.getdict();
    if("__builtins__" !in locals) {
        auto builtins = new PydObject(PyEval_GetBuiltins());
        locals["__builtins__"] = builtins;
    }
    auto pres = PyRun_String(
            zcc(python), 
            Py_file_input, locals.ptr, locals.ptr);
    if(pres) {
        Py_DECREF(pres);
    }else{
        auto z = interceptStderr();
        writefln("z: %s", z);
        throw new Exception(z);
    }
}

alias PyDef!("def func1(a): 
    return a*2+1", int, int) func1;

void main() {
    assert(func1(1) == 3);    
    assert(func1(2) == 5);    
    assert(func1(3) == 7);    
    dictTests();
    seqTests();
    numberTests();
    int i = PyEval!int("1+2");
    writeln(i);
    PyStmts(q"<
class X:
    def __init__(self):
        self._a = "loogie sniffers"
    def a(self):
        print self._a
        >");
    auto x = PyEval("X()");
    x.method("a");
    PyStmts(q"<
print 'hi there!'
print 'I am a taco!'
import tacotruck
tacotruck.run_tacotruck()
>");
    PyStmts(q"<print "cheezit: %x" % ~0x10000000 >");
}

void dictTests() {
    auto g = py(["a":"b"]);
    assert((g.keys()).toString() == "['a']");
    assert((g.values()).toString() == "['b']");
    assert(g.items().toString() == "[('a', 'b')]");
    assert(g["a"].toString()  == "b");
    g["b"] = py("truck");
    assert(g.items().toString() == "[('a', 'b'), ('b', 'truck')]" ||
            g.items().toString() == "[('b', 'truck'), ('a', 'b')]");
    foreach(key, val; g) {
        if (key.toString() == "a") assert(val.toString == "b");
        else if (key.toString() == "b") assert(val.toString == "truck");
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

void seqTests() {
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

}

void numberTests() {
    auto n = py(1);
    n = n + py(2);
    assert(n == py(3));
    n = n * py(12);
    assert(n == py(36));
    n = n / py(5);
    assert(n == py(7));
    n = py(36).floorDiv(py(5));
    assert(n == py(7));
    n = py(36).trueDiv(py(5));
    assert(n == py(7.2)); // *twitch*
    n = (py(37).divmod(py(5)));
    assert(n.toString() == "(7, 2)");
    n = py(37) % py(5);
    assert(n == py(2));
    n = py(3) ^^ py(4);
    assert(n == py(81));
    // holy guacamole! I didn't know python's pow() did this!
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
