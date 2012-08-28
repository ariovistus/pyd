module python2.code;

import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/code.h:

struct PyCodeObject { /* Bytecode object */
    mixin PyObject_HEAD;

    int co_argcount;
    int co_nlocals;
    int co_stacksize;
    int co_flags;
    PyObject* co_code;
    PyObject* co_consts;
    PyObject* co_names;
    PyObject* co_varnames;
    PyObject* co_freevars;
    PyObject* co_cellvars;

    PyObject* co_filename;
    PyObject* co_name;
    int co_firstlineno;
    PyObject* co_lnotab;
    version(Python_2_5_Or_Later) {
        void *co_zombieframe;
    }
    version(Python_2_7_Or_Later) {
        PyObject* co_weakreflist;
    }

}

/* Masks for co_flags above */
enum int CO_OPTIMIZED   = 0x0001;
enum int CO_NEWLOCALS   = 0x0002;
enum int CO_VARARGS     = 0x0004;
enum int CO_VARKEYWORDS = 0x0008;
enum int CO_NESTED      = 0x0010;
enum int CO_GENERATOR   = 0x0020;
enum int CO_NOFREE      = 0x0040;

version(Python_2_5_Or_Later){
    // Removed in 2.5
}else{
    enum int CO_GENERATOR_ALLOWED      = 0x1000;
}
enum int CO_FUTURE_DIVISION        = 0x2000;
version(Python_2_5_Or_Later){
    enum int CO_FUTURE_ABSOLUTE_IMPORT = 0x4000;
    enum int CO_FUTURE_WITH_STATEMENT  = 0x8000;
    enum int CO_FUTURE_PRINT_FUNCTION  = 0x10000;
    enum int CO_FUTURE_UNICODE_LITERALS  = 0x20000;
}

enum int CO_MAXBLOCKS = 20;

// &PyCode_Type is accessible via PyCode_Type_p.
__gshared PyTypeObject PyCode_Type;

// D translations of C macros:
int PyCode_Check()(PyObject* op) {
    return op.ob_type == &PyCode_Type;
}
size_t PyCode_GetNumFree()(PyObject* op) {
    return PyObject_Length((cast(PyCodeObject *) op).co_freevars);
}

PyCodeObject* PyCode_New(
        int, int, int, int, PyObject* , PyObject* , PyObject* , PyObject* ,
        PyObject* , PyObject* , PyObject* , PyObject* , int, PyObject* );
version(Python_2_7_Or_Later) {
    PyCodeObject* PyCode_NewEmpty(const(char)* filename, 
            const(char)* funcname, int firstlineno);
}
int PyCode_Addr2Line(PyCodeObject *, int);

struct PyAddrPair {
    int ap_lower;
    int ap_upper;
}

int PyCode_CheckLineNumber(PyCodeObject* co, int lasti, PyAddrPair *bounds);
version(Python_2_6_Or_Later){
    PyObject* PyCode_Optimize(PyObject* code, PyObject* consts,
            PyObject* names, PyObject* lineno_obj);
}

