import pyd.pyd, pyd.embedded;

int a(int i) {
    return 10;
}

int a(double d){
    return 20;
}

int a2(int i, double d=4.5) {
    return cast(int) (100*d + i);
}

int a3(int[] i...) {
    int ret = 42;
    foreach(_i; i) ret += _i;
    return ret;
}

static this() {
    def!("testing", a,int function(double))(""); 
    def!("testing", a2, int function(int,double,))(""); 
    def!("testing", a3, int function(int[]))(""); 
    add_module("testing");
}

unittest{
    assert(PyEval!int("a(1.0)","testing") == 20);
    assert(PyEval!int("a2(4,2.1)","testing") == 214);
    assert(PyEval!int("a2(4)","testing") == 454);
    assert(PyEval!int("a2(i=4)","testing") == 454);
    assert(PyEval!int("a3(4)","testing") == 46);
    assert(PyEval!int("a3(i=4)","testing") == 46);
    assert(PyEval!int("a3(4,3)","testing") == 49);
    assert(PyEval!int("a3(i=[4,3])","testing") == 49);
}

void main() {}
