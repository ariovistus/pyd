import pyd.pyd, pyd.embedded;
import python: Py_ssize_t;
import std.stdio;

static this() {
    add_module("testing");
    wrap_class!(Bizzy,
            Init!(int[]),
            //Init!(int,double),
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
}

class Bizzy {
    int _m;

    int m() { return _m; }

    this(int[] i...) {
        writeln("abooba",i);
    }
    this(int i, double d = 1.0) {
        writeln("shawarma");
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

unittest {
    PyStmts(q"{
bizzy=Bizzy(1,2,3,4,5)
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

}

void main() {}
