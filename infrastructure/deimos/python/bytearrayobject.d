/**
 * Mirror _bytearrayobject.h
 *
 * Type PyByteArrayObject represents a mutable array of bytes.
 * The Python API is that of a sequence;
 * the bytes are mapped to ints in [0, 256).
 * Bytes are not characters; they may be used to encode characters.
 * The only way to go between bytes and str/unicode is via encoding
 * and decoding.
 * For the convenience of C programmers, the bytes type is considered
 * to contain a char pointer, not an unsigned char pointer.
 */
module deimos.python.bytearrayobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/bytearrayobject.h:

version(Python_2_6_Or_Later) {
    /// subclass of PyVarObject
    /// Availability: >= 2.6
    struct PyByteArrayObject {
        mixin PyObject_VAR_HEAD!();
        version(Python_3_4_Or_Later) {
            /// _
            Py_ssize_t ob_alloc;
            /// _
            char* ob_bytes;
            /// _
            char* ob_start;
            /// _
            int ob_exports;
        }else{
            /** how many buffer exports */
            int ob_exports;
            /** How many bytes allocated */
            Py_ssize_t ob_alloc;
            /// _
            char* ob_bytes;
        }

    }

    /* Type object */
/// Availability: >= 2.6
    mixin(PyAPI_DATA!"PyTypeObject PyByteArray_Type");
/// Availability: >= 2.6
    mixin(PyAPI_DATA!"PyTypeObject PyByteArrayIter_Type");

    /** Type check macro
Availability: >= 2.6
     */
    int PyByteArray_Check()(PyObject* self) {
        return PyObject_TypeCheck(self, &PyByteArray_Type);
    }

    /** Type check macro
 Availability: >= 2.6
 */
    int PyByteArray_CheckExact()(PyObject* self) {
        return Py_TYPE(self) == &PyByteArray_Type;
    }

    /* Direct API functions */
    /// Availability: >= 2.6
    PyObject* PyByteArray_FromObject(PyObject*);
    /// Availability: >= 2.6
    PyObject* PyByteArray_Concat(PyObject*, PyObject*);
    /// Availability: >= 2.6
    PyObject* PyByteArray_FromStringAndSize(const char*, Py_ssize_t);
    /// Availability: >= 2.6
    Py_ssize_t PyByteArray_Size(PyObject*);
    /// Availability: >= 2.6
    char* PyByteArray_AsString(PyObject*);
    /// Availability: >= 2.6
    int PyByteArray_Resize(PyObject*, Py_ssize_t);
    /// template trading safety for speed
    /// Availability: >= 2.6
    char* PyByteArray_AS_STRING()(PyObject* self) {
        assert(PyByteArray_Check(self));
        if(Py_SIZE(self)) {
            return (cast(PyByteArrayObject*) self).ob_bytes;
        }else{
            return "\0".ptr;
        }
    }
    /// template trading safety for speed
    /// Availability: >= 2.6
    auto PyByteArray_GET_SIZE()(PyObject* self) {
        assert(PyByteArray_Check(self));
        return Py_SIZE(cast(PyVarObject*) self);
    }
}
