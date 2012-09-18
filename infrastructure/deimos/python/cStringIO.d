module deimos.python.cStringIO;

import deimos.python.pyport;
import deimos.python.object;

version(Python_3_0_Or_Later) {
}else{
extern(C):
// Python-header-file: Include/cStringIO.h:

PycStringIO_CAPI* PycStringIO = null;

PycStringIO_CAPI* PycString_IMPORT()() {
    if (PycStringIO == null) {
        PycStringIO = cast(PycStringIO_CAPI *)
            PyCObject_Import(cast(char*) "cStringIO\0".ptr, cast(char*) "cStringIO_CAPI\0".ptr);
    }
    return PycStringIO;
}

struct PycStringIO_CAPI {
    int function(PyObject*, char**, Py_ssize_t) cread;
    int function(PyObject*, char**) creadline;
    int function(PyObject*, Char1*, Py_ssize_t) cwrite;
    PyObject* function(PyObject*) cgetvalue;
    PyObject* function(int) NewOutput;
    PyObject* function(PyObject*) NewInput;
    PyTypeObject* InputType;
    PyTypeObject* OutputType;
}

// D translations of C macros:
int PycStringIO_InputCheck()(PyObject* o) {
    return Py_TYPE(o) == PycStringIO.InputType;
}
int PycStringIO_OutputCheck()(PyObject* o) {
    return Py_TYPE(o) == PycStringIO.OutputType;
}


}
