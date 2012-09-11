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
    def!(a,int function(double), ModuleName!"testing")(); 
    def!(a2, int function(int,double,), ModuleName!"testing")(); 
    def!(a3, int function(int[]), ModuleName!"testing")(); 
    add_module("testing");
}

unittest{
    assert(py_eval!int("a(1.0)","testing") == 20);
    assert(py_eval!int("a2(4,2.1)","testing") == 214);
    assert(py_eval!int("a2(4)","testing") == 454);
    assert(py_eval!int("a2(i=4)","testing") == 454);
    assert(py_eval!int("a3(4)","testing") == 46);
    assert(py_eval!int("a3(i=4)","testing") == 46);
    assert(py_eval!int("a3(4,3)","testing") == 49);
    assert(py_eval!int("a3(i=[4,3])","testing") == 49);
}

void main() {}
