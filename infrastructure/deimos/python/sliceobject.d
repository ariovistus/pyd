module deimos.python.sliceobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/sliceobject.h:

__gshared PyObject _Py_EllipsisObject;

@property PyObject* Py_Ellipsis()() {
    return &_Py_EllipsisObject;
}

struct PySliceObject {
    mixin PyObject_HEAD;

    PyObject* start;
    PyObject* stop;
    PyObject* step;
}

__gshared PyTypeObject PySlice_Type;

// D translation of C macro:
int PySlice_Check()(PyObject* op) {
    return Py_TYPE(op) == &PySlice_Type;
}

PyObject* PySlice_New(PyObject* start, PyObject* stop, PyObject* step);
// before python 3.2, r was typed as PySliceObject*, but bah humbug.
int PySlice_GetIndices(PyObject* r, Py_ssize_t length,
        Py_ssize_t* start, Py_ssize_t* stop, Py_ssize_t* step);
// before python 3.2, r was typed as PySliceObject*, but bah humbug.
int PySlice_GetIndicesEx(PyObject* r, Py_ssize_t length,
        Py_ssize_t* start, Py_ssize_t* stop,
        Py_ssize_t* step, Py_ssize_t* slicelength);


