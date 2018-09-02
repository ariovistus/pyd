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

    version(Python_3_4_Or_Later) {
        /// _
        struct _PyManagedBufferObject {
            mixin PyObject_HEAD;
            /// _
            int flags;
            /// _
            Py_ssize_t exports;
            /// _
            Py_buffer master;
        }
    }
	enum _Py_MEMORYVIEW_MAX_FORMAT = 3;

    /// subclass of PyObject
    /// Availability: >= 2.7
    struct PyMemoryViewObject {
        version(Python_3_4_Or_Later) {
			mixin PyObject_VAR_HEAD;

            /// _
			_PyManagedBufferObject* mbuf;
            /// _
			Py_hash_t hash;
            /// _
			int flags;
            /// _
			Py_ssize_t exports;
            /// _
			Py_buffer view;
            version(Python_3_5_Or_Later) {
            }else{
                /// Availability: 3.4
                char[_Py_MEMORYVIEW_MAX_FORMAT] format;
            }
            /// _
			PyObject* weakreflist;
            /// _
			Py_ssize_t[1] _ob_array;

            /// _
            @property Py_ssize_t* ob_array()() {
                return _ob_array.ptr;
            }
        }else{
            mixin PyObject_HEAD;
            /// Availability: 2.7
            PyObject* base;
            /// _
            Py_buffer view;
        }
    }

}
