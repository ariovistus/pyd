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
/// _
int PyGen_NeedsFinalizing(PyGenObject*);

