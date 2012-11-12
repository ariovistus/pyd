
struct PyObject{ }

extern(C) alias PyObject* function(PyObject*) PyFun1;
extern(C) alias PyObject* function(PyObject*, PyObject*) PyFun2;
extern(C) alias PyObject* function(long) PyLFun1;
extern(C) alias PyObject* function(ulong) PyLUFun1;
extern(C) alias PyObject* function(const(char)* buf, size_t len) PyStrFun1;
extern(C) alias PyObject* function(const(char)* str) PyStrFun2;

struct Funs{
    static __gshared:
    PyStrFun2 raise;
    PyLFun1 long_to_python;
    PyLUFun1 ulong_to_python;
    PyStrFun1 utf8_to_python;

    PyFun2 get_item;
}

extern(C) int pyd_reg_fun(char* _fnom, PyFun1 somefun) {
    import std.conv;
    import std.exception;
    import std.traits;
    import std.typetuple;
    import std.stdio;
    string fnom = to!string(_fnom);
    alias TypeTuple!(__traits(allMembers, Funs)) Fields;
    foreach(i,_; Fields) {
        enum string nom = _;
        if(nom == fnom) {
            writefln("Funs[%s]: %s", i, nom);
            mixin("Funs."~nom ~ " = cast(typeof(Funs."~nom~")) somefun;");
            return 0;
        }
    }
    enforce(0);
    return 0;
}
