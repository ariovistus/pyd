/**
  Mirror context.h

  */
module deimos.python.context;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.internal.context;

extern(C):

version(Python_3_7_Or_Later) {
    mixin(PyAPI_DATA!"PyTypeObject PyContext_Type");
    mixin(PyAPI_DATA!"PyTypeObject PyContextVar_Type");
    mixin(PyAPI_DATA!"PyTypeObject PyContextToken_Type");

    bool PyContext_CheckExact()(PyObject* o) {
        return Py_TYPE(o) == &PyContext_Type;
    }

    bool PyContextVar_CheckExact()(PyObject* o) {
        return Py_TYPE(o) == &PyContextVar_Type;
    }

    bool PyContextToken_CheckExact()(PyObject* o) {
        return Py_TYPE(o) == &PyContextToken_Type;
    }

    PyContext* PyContext_New();
    PyContext* PyContext_Copy(PyContext*);
    PyContext* PyContext_CopyCurrent();

    PyContext* PyContext_Enter(PyContext*);
    PyContext* PyContext_Exit(PyContext*);

    PyContextVar* PyContextVar_New(char* name, PyObject* default_value);

    int PyContextVar_Get(PyContextVar* var, PyObject* default_value, PyObject** value);

    PyContextToken* PyContextVar_Set(PyContextVar* var, PyObject* value);

    int PyContextVar_Reset(PyContextVar* var, PyContextToken* token);

    int PyContext_ClearFreeList();
}
