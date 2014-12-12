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

int t1(T)(T i) {
    return 1;
}

template t2(T) {
    int f(T t) {
        return 1;
    }
}

void test() {
    import std.stdio;
    writeln("IMATEST");
}

static this() {
    def!(a,int function(double), ModuleName!"testing")(); 
    def!(a2, int function(int,double,), ModuleName!"testing")(); 
    def!(a3, int function(int[]), ModuleName!"testing")(); 
    def!(a4, ModuleName!"testing")(); 
    def!(test, ModuleName!"testing")(); 
    def!(t1!int, PyName!"t1", ModuleName!"testing")(); 
    def!(t2!int.f, PyName!"t2", ModuleName!"testing")(); 
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

int main(string[] args) {
    InterpContext c = new InterpContext();
    c.py_stmts("import nose");
    c.py_stmts("import sys");
    c.argv = args;
    c.py_stmts("sys.argv = argv");
    c.py_stmts("
from unittest import TestCase
import testing
class MyTests(TestCase):
    def test_something(self):
        self.assertEqual(1, 2)
print ('nose: ', nose.__file__)
print ('stdout: ', sys.stdout)
testing.MyTests = MyTests
print ('testing: ', dir(testing))
");
    c.py_stmts("print(str(MyTests))");
    try{
        return c.py_eval!int("nose.run(module=testing)");
    }catch(PythonException e) {
        c.ex = e.traceback();
        c.py_stmts("import traceback; traceback.print_tb(ex)");
        throw e;
    }
    return 1;
}
