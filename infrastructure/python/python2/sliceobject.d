module python2.sliceobject;

import python2.types;
import python2.object;

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

// &PySlice_Type is accessible via PySlice_Type_p.
__gshared PyTypeObject PySlice_Type;
// D translation of C macro:
int PySlice_Check()(PyObject* op) {
    return Py_TYPE(op) == &PySlice_Type;
}

PyObject* PySlice_New(PyObject* start, PyObject* stop, PyObject* step);
int PySlice_GetIndices(PySliceObject* r, Py_ssize_t length,
        Py_ssize_t* start, Py_ssize_t* stop, Py_ssize_t* step);
int PySlice_GetIndicesEx(PySliceObject* r, Py_ssize_t length,
        Py_ssize_t* start, Py_ssize_t* stop,
        Py_ssize_t* step, Py_ssize_t* slicelength);


