import pyd.def;
import pyd.exception;

extern(C) void PydMain();

version(Python_3_0_Or_Later) {
    import deimos.python.Python;
    pragma(msg, "in here!");
    extern(C) export PyObject* PyInit_%(modulename)s() {
        return pyd.exception.exception_catcher(delegate PyObject*() {
                pyd.def.pyd_module_name = "%(modulename)s";
                PydMain();
                return pyd.def.pyd_modules[""];
                });
    }
}else version(Python_2_4_Or_Later) {
    extern(C) export void init%(modulename)s() {
        pyd.exception.exception_catcher(delegate void() {
                pyd.def.pyd_module_name = "%(modulename)s";
                PydMain();
                });
    }
}else static assert(false);

extern(C) void _Dmain(){
    // make druntime happy
}
