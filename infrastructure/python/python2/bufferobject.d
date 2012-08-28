module python2.bufferobject;

import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/bufferobject.h:

__gshared PyTypeObject PyBuffer_Type;

// D translation of C macro:
int PyBuffer_Check()(PyObject* op) {
    return op.ob_type == &PyBuffer_Type;
}

enum Py_END_OF_BUFFER = -1;

PyObject* PyBuffer_FromObject(PyObject* base, Py_ssize_t offset, Py_ssize_t size);
PyObject* PyBuffer_FromReadWriteObject(PyObject* base, Py_ssize_t offset, Py_ssize_t size);

PyObject* PyBuffer_FromMemory(void* ptr, Py_ssize_t size);
PyObject* PyBuffer_FromReadWriteMemory(void* ptr, Py_ssize_t size);

PyObject* PyBuffer_New(Py_ssize_t size);


