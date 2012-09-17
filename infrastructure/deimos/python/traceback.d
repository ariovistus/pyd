module deimos.python.traceback;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.frameobject;

extern(C):
// Python-header-file: Include/traceback.h:

struct PyTracebackObject {
    mixin PyObject_HEAD;

    PyTracebackObject* tb_next;
    PyFrameObject* tb_frame;
    int tb_lasti;
    int tb_lineno;
}

int PyTraceBack_Here(PyFrameObject*);
int PyTraceBack_Print(PyObject*, PyObject*);
version(Python_3_2_Or_Later) {
    int _Py_DisplaySourceLine(PyObject*, PyObject*, int, int);
}else version(Python_2_6_Or_Later){
    int _Py_DisplaySourceLine(PyObject*, const(char)*, int, int);
}

__gshared PyTypeObject PyTraceBack_Type;

// D translation of C macro:
int PyTraceBack_Check()(PyObject* v) {
    return v.ob_type == &PyTraceBack_Type;
}


