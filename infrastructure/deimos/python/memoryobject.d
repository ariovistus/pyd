/**
  Mirror _memoryobject.h
  */
module deimos.python.memoryobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/memoryobject.h:
version(Python_2_7_Or_Later) {
    /// Availability: >= 2.7
    mixin(PyAPI_DATA!"PyTypeObject PyMemoryView_Type");

    /// Availability: >= 2.7
    int PyMemoryView_Check()(PyObject* op) {
        return Py_TYPE(op) == &PyMemoryView_Type;
    }

    /// Availability: >= 2.7
    auto PyMemoryView_GET_BUFFER()(PyObject* op) {
        return &(cast(PyMemoryViewObject*)op).view;
    }

    /// Availability: >= 2.7
    auto PyMemoryView_GET_BASE()(PyObject* op) {
        return (cast(PyMemoryViewObject*) op).view.obj;
    }

    /// Availability: >= 2.7
    PyObject* PyMemoryView_GetContiguous(PyObject* base,
            int buffertype, char fort);

    /// Availability: >= 2.7
    PyObject* PyMemoryView_FromObject(PyObject* base);

    /// Availability: >= 2.7
    PyObject* PyMemoryView_FromBuffer(Py_buffer* info);

    /// subclass of PyObject
    /// Availability: >= 2.7
    struct PyMemoryViewObject {
        mixin PyObject_HEAD;
        version(Python_3_0_Or_Later) {
        }else{
            /// Availability: 2.7
            PyObject* base;
        }
        /// _
        Py_buffer view;
    }

}
