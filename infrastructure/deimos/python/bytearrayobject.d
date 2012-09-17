module deimos.python.bytearrayobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/bytearrayobject.h:

version(Python_2_6_Or_Later) {
    struct PyByteArrayObject {
        mixin PyObject_VAR_HEAD!();
        int ob_exports;
        Py_ssize_t ob_alloc;
        char* ob_bytes;
    }

    /* Type object */
    PyTypeObject PyByteArray_Type;
    PyTypeObject PyByteArrayIter_Type;

    /* Type check macros */
    int PyByteArray_Check()(PyObject* self) {
        return PyObject_TypeCheck(self, PyByteArray_Type_p);
    }

    int PyByteArray_CheckExact()(PyObject* self) {
        return Py_TYPE(self) == PyByteArray_Type_p;
    }

    /* Direct API functions */
    PyObject* PyByteArray_FromObject(PyObject*);
    PyObject* PyByteArray_Concat(PyObject*, PyObject*);
    PyObject* PyByteArray_FromStringAndSize(const char*, Py_ssize_t);
    Py_ssize_t PyByteArray_Size(PyObject*);
    char* PyByteArray_AsString(PyObject*);
    int PyByteArray_Resize(PyObject*, Py_ssize_t);

    char* PyByteArray_AS_STRING()(PyObject* self) {
        assert(PyByteArray_Check(self));
        if(Py_SIZE(self)) {
            return (cast(PyByteArrayObject*) self).ob_bytes;
        }else{
            return "\0".ptr;
        }
    }

    auto PyByteArray_GET_SIZE(PyObject* self) {
        assert(PyByteArray_Check(self));
        return Py_SIZE(self);
    }



}
