import pyd.pyd, pyd.embedded;
import std.string;

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

string a4(string s1, int i1, string s2 = "friedman", int i2 = 4, string s3 = "jefferson") {
    return std.string.format("<'%s', %s, '%s', %s, '%s'>", s1,i1,s2,i2,s3);
}

static this() {
    def!(a,int function(double), ModuleName!"testing")(); 
    def!(a2, int function(int,double,), ModuleName!"testing")(); 
    def!(a3, int function(int[]), ModuleName!"testing")(); 
    def!(a4, ModuleName!"testing")(); 
    on_py_init({
            add_module!(ModuleName!"testing")();
    });
    py_init();
}

unittest{
    InterpContext c = new InterpContext();
    c.py_stmts("from testing import *");

    assert(c.py_eval!int("a(1.0)") == 20);
    assert(c.py_eval!int("a2(4,2.1)") == 214);
    assert(c.py_eval!int("a2(4)") == 454);
    assert(c.py_eval!int("a2(i=4)") == 454);
    assert(c.py_eval!int("a3(4)") == 46);
    assert(c.py_eval!int("a3(i=4)") == 46);
    assert(c.py_eval!int("a3(4,3)") == 49);
    assert(c.py_eval!int("a3(i=[4,3])") == 49);
    assert(c.py_eval!string("a4('hi',2,s3='zi')") == 
            "<'hi', 2, 'friedman', 4, 'zi'>");


}

void main() {}
