module deimos.python.frameobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.code;
import deimos.python.pystate;


extern(C):
// Python-header-file: Include/frameobject.h:

struct PyTryBlock {
    int b_type;
    int b_handler;
    int b_level;
}

struct PyFrameObject {
    mixin PyObject_VAR_HEAD;

    PyFrameObject* f_back;
    PyCodeObject* f_code;
    PyObject* f_builtins;
    PyObject* f_globals;
    PyObject* f_locals;
    PyObject** f_valuestack;
    PyObject** f_stacktop;
    PyObject* f_trace;
    PyObject* f_exc_type;
    PyObject* f_exc_value;
    PyObject* f_exc_traceback;
    PyThreadState* f_tstate;
    int f_lasti;
    int f_lineno;
    version(Python_2_5_Or_Later){
    }else{
        int f_restricted;
    }
    int f_iblock;
    PyTryBlock f_blockstack[CO_MAXBLOCKS];
    version(Python_2_5_Or_Later){
    }else{
        int f_nlocals;
        int f_ncells;
        int f_nfreevars;
        int f_stacksize;
    }
    PyObject* _f_localsplus[1];
    PyObject** f_localsplus()() {
        return _f_localsplus.ptr;
    }
}

__gshared PyTypeObject PyFrame_Type;

// D translation of C macro:
int PyFrame_Check()(PyObject* op) {
    return Py_TYPE(op) == &PyFrame_Type;
}
version(Python_3_0_Or_Later){
}else version(Python_2_5_Or_Later){
    int PyFrame_IsRestricted()(PyFrameObject* f) {
        return f.f_builtins != f.f_tstate.interp.builtins;
    }
}

PyFrameObject* PyFrame_New(PyThreadState*, PyCodeObject*,
        PyObject*, PyObject*);

void PyFrame_BlockSetup(PyFrameObject*, int, int, int);
PyTryBlock* PyFrame_BlockPop(PyFrameObject*);
PyObject** PyFrame_ExtendStack(PyFrameObject*, int, int);

void PyFrame_LocalsToFast(PyFrameObject*, int);
void PyFrame_FastToLocals(PyFrameObject*);
version(Python_2_6_Or_Later) {
    int PyFrame_ClearFreeList();
}
version(Python_2_7_Or_Later) {
    int PyFrame_GetLineNumber(PyFrameObject*);
}


