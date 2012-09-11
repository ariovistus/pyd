import pyd.pyd, pyd.embedded;

static this() {
    add_module("testing");
}
// py_def
unittest {
    alias py_def!(q"<def func1(a): 
            return a*2+1>","testing", int, int) func1;
    assert(func1(1) == 3);    
    assert(func1(2) == 5);    
    assert(func1(3) == 7);    
}

void main() {}
