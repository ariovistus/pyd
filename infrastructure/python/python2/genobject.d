module python2.genobject;

import python2.types;
import python2.object;
import python2.frameobject;

extern(C):
// Python-header-file: Include/genobject.h:

struct PyGenObject {
    mixin PyObject_HEAD;
    PyFrameObject* gi_frame;
    int gi_running;
    version(Python_2_6_Or_Later){
        /* The code object backing the generator */
        PyObject* gi_code;
    }
    PyObject* gi_weakreflist;
}

__gshared PyTypeObject PyGen_Type;

// D translations of C macros:
int PyGen_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, &PyGen_Type);
}
int PyGen_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyGen_Type;
}

PyObject* PyGen_New(PyFrameObject*);
int PyGen_NeedsFinalizing(PyGenObject*);

