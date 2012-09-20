import pyd.pyd, pyd.embedded;

static this() {
    on_py_init({
    add_module!(ModuleName!"testing")();
    });
    py_init();
}
// py_def
unittest {
    alias py_def!(
            "def func1(a):\n"
            " return a*2+1",
            "testing", 
            int function(int)) func1;
    assert(func1(1) == 3);    
    assert(func1(2) == 5);    
    assert(func1(3) == 7);    
}

void main() {}
