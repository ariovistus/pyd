/**
  Mirror _traceback.h

  Traceback interface
  */
module deimos.python.traceback;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.frameobject;

extern(C):
// Python-header-file: Include/traceback.h:

/// _
struct PyTracebackObject {
    mixin PyObject_HEAD;

    /// _
    PyTracebackObject* tb_next;
    /// _
    PyFrameObject* tb_frame;
    /// _
    int tb_lasti;
    /// _
    int tb_lineno;
}

/// _
int PyTraceBack_Here(PyFrameObject*);
/// _
int PyTraceBack_Print(PyObject*, PyObject*);
version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    int _Py_DisplaySourceLine(PyObject*, PyObject*, int, int);
}else version(Python_2_6_Or_Later){
    /// Availability: 2.6, 2.7, 3.0
    int _Py_DisplaySourceLine(PyObject*, const(char)*, int, int);
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PyTraceBack_Type");

// D translation of C macro:
/// _
int PyTraceBack_Check()(PyObject* v) {
    return v.ob_type == &PyTraceBack_Type;
}


