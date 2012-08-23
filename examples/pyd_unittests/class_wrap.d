import pyd.pyd, pyd.embedded;
import python: Py_ssize_t;
import std.stdio;

static this() {
    add_module("testing");
    wrap_class!(Bizzy,
            //Init!(int[]),
            Init!(int,double,string),
            Def!(Bizzy.a, int function(double)), 
            StaticDef!(Bizzy.b, int function(double)),
            Repr!(Bizzy.repr),
            Property!(Bizzy.m, true),
            OpBinary!("+"),
            OpBinary!("*"),
            OpBinary!("^^"),
            OpBinaryRight!("in"),
            OpBinaryRight!("+"),
            OpUnary!("+"),
            OpUnary!("~"),
            OpAssign!("+"),
            OpAssign!("%"),
            OpAssign!("^^"),
            OpIndex!(),
            OpIndexAssign!(),
            OpCompare!(),
            OpSlice!(),
            OpSliceAssign!(),
            OpCall!(double),
            Len!(Bizzy.pylen),
    )("","testing");
    wrap_class!(Bizzy2,
            Init!(int[]),
    )("","testing");
    wrap_class!(Bizzy3,
            Init!(int,int),
    )("","testing");
}

class Bizzy {
    int _m;

    int m() { return _m; }

    this(int i, double d = 1.0, string s = "hi") {
        writefln("shawarma i=%s, d=%s, s='%s'",i,d,s);
    }

    int a(int i){
        return i + 11;
    }
    int a(double d) {
        return cast(int)( d+12);
    }
    static int b(int i){
        return i + 13;
    }
    static int b(double d) {
        return cast(int)( d+14);
    }

    string repr(int i) {
        return "hi";
    }
    string repr() {
        return "bye";
    }
    int opBinary(string op)(int i) {
        static if(op == "+") return i+1;
        else static if(op == "*") return i+2;
        else static if(op == "^^") return i+3;
        else static assert(0);
    }
    bool opBinaryRight(string op)(int i) if(op == "in") {
        return i > 10;
    }

    int opBinaryRight(string op)(int i) if(op == "+") {
        return i + 4;
    }

    void opOpAssign(string op)(int i) {
        static if(op == "+") _m = i + 22;
        else static if(op == "%") _m = i + 33;
        else static if(op == "^^") _m = i + 44;
        else static assert(0);
    }

    int opUnary(string op)() {
        static if(op == "+") return 55;
        else static if(op == "~") return 44;
        else static assert(0);
    }

    override int opCmp(Object p) {
        return 10;
    }

    double opIndex(int i) {
        return i*4.4;
    }

    int[] opSlice(Py_ssize_t a, Py_ssize_t b) {
        return [1,2,3];
    }

    void opIndexAssign(double d, int i) {
        _m = cast(int)(d*1000) + i;
    }

    void opSliceAssign(double d, Py_ssize_t a, Py_ssize_t b) {
        _m = cast(int)(d*1000) + cast(int)(a*10 + b);
    }

    Py_ssize_t pylen(){
        return 401;
    }

    int opCall(double d) {
        return _m + cast(int)(1000 *d);
    }
}

class Bizzy2 {
    this(int[] i...) {
        writeln("abooba",i);
    }
}

class Bizzy3{
    this(int i, int j) {
        writefln("broomba(%s,%s)",i,j);
    }
}

unittest {
    PyStmts(q"{
#bizzy=Bizzy(1,2,3,4,5)
#bizzy=Bizzy(d=7.1,i=4)
bizzy=Bizzy(i=4)
assert bizzy.a(1.0) == 13
assert Bizzy.b(1.0) == 15
assert repr(bizzy) == "bye"
assert bizzy+1 == 2
assert bizzy*1 == 3
assert bizzy**1 == 4
assert 1+bizzy == 5
assert 19 in bizzy
assert 0 not in bizzy 
assert +bizzy == 55
assert ~bizzy == 44
assert bizzy > 1
assert len(bizzy) == 401
assert bizzy[1:2] == [1,2,3]
bizzy += 2
assert bizzy.m == 24
bizzy %= 3
assert bizzy.m == 36
bizzy **= 4
assert bizzy.m == 48
bizzy[2] = 3.3
assert bizzy.m == 3302
bizzy[2:3] = 4.3
assert bizzy.m == 4323
assert bizzy(40.5) == 44823
}", "testing");

PyStmts(q"{
bizzy = Bizzy2(4);
bizzy = Bizzy2([4,5]);
bizzy = Bizzy2(i=4);
bizzy = Bizzy2(i=[4,5]);
}", "testing");

PyStmts(q"{
bizzy = Bizzy3(1,2)
}", "testing");

}

void main() {}
