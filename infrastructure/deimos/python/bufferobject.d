/**
  mirror _bufferobject.h

  (note bufferobject.h does not exist in python 3)
  */
module deimos.python.bufferobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/bufferobject.h:

version(Python_3_0_Or_Later) {
    // no bufferobject in python 3
}else{

/// Availability: 2.*
mixin(PyAPI_DATA!"PyTypeObject PyBuffer_Type");

// D translation of C macro:
/// Availability: 2.*
int PyBuffer_Check()(PyObject* op) {
    return op.ob_type == &PyBuffer_Type;
}

/// Availability: 2.*
enum Py_END_OF_BUFFER = -1;

/// Availability: 2.*
PyObject* PyBuffer_FromObject(
        PyObject* base,
        Py_ssize_t offset,
        Py_ssize_t size);
/// Availability: 2.*
PyObject* PyBuffer_FromReadWriteObject(
        PyObject* base,
        Py_ssize_t offset,
        Py_ssize_t size);
/// Availability: 2.*
PyObject* PyBuffer_FromMemory(void* ptr, Py_ssize_t size);
/// Availability: 2.*
PyObject* PyBuffer_FromReadWriteMemory(void* ptr, Py_ssize_t size);
/// Availability: 2.*
PyObject* PyBuffer_New(Py_ssize_t size);


}
