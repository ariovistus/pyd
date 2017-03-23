/**
  Mirror _genobject.h

  Generator object interface
 */
module deimos.python.genobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.frameobject;

extern(C):
// Python-header-file: Include/genobject.h:

template _PyGenObject_HEAD(string prefix) {
    mixin("
        mixin PyObject_HEAD;
        PyFrameObject* " ~ prefix ~ "_frame;
        char " ~ prefix ~ "_running;
        PyObject* " ~ prefix ~ "_code;
        PyObject* " ~ prefix ~ "_weakreflist;
        PyObject* " ~ prefix ~ "_name;
        PyObject* " ~ prefix ~ "_qualname;
    ");
}

version(Python_3_5_Or_Later) {
    struct PyGenObject {
        mixin _PyGenObject_HEAD!("gi");
    }
}else{
    struct PyGenObject {
        mixin PyObject_HEAD;
        /** The gi_ prefix is intended to remind of generator-iterator.

        Note: gi_frame can be NULL if the generator is "finished"
         */
        PyFrameObject* gi_frame;
        /** True if generator is being executed. */
        int gi_running;
        version(Python_2_6_Or_Later){
            /** The code object backing the generator */
            /// Availability: >= 2.6
            PyObject* gi_code;
        }
        /** List of weak reference. */
        PyObject* gi_weakreflist;
    }
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PyGen_Type");

// D translations of C macros:
/// _
int PyGen_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, &PyGen_Type);
}
/// _
int PyGen_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyGen_Type;
}

/// _
PyObject* PyGen_New(PyFrameObject*);

version(Python_3_5_Or_Later) {
    /// _
    PyObject* PyGen_NewWithQualName(PyFrameObject*, PyObject*, PyObject*);
}

/// _
int PyGen_NeedsFinalizing(PyGenObject*);

version(Python_3_5_Or_Later) {
    /// _
    int _PyGen_SetStopIterationValue(PyObject*);
}
