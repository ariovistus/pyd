module deimos.python.moduleobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/moduleobject.h:

__gshared PyTypeObject PyModule_Type;

// D translation of C macro:
int PyModule_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, &PyModule_Type);
}
// D translation of C macro:
int PyModule_CheckExact()(PyObject *op) {
    return Py_TYPE(op) == &PyModule_Type;
}

PyObject* PyModule_New(Char1*);
PyObject_BorrowedRef* PyModule_GetDict(PyObject*);
const(char)* PyModule_GetName(PyObject*);
const(char)* PyModule_GetFilename(PyObject*);
version(Python_3_0_Or_Later) {
    PyObject* PyModule_GetFilenameObject(PyObject*);
}
void _PyModule_Clear(PyObject*);

version(Python_3_0_Or_Later) {
    PyModuleDef* PyModule_GetDef(PyObject*);
    void* PyModule_GetState(PyObject*);

    struct PyModuleDef_Base {
        mixin PyObject_HEAD;
        PyObject* function() m_init;
        Py_ssize_t m_index;
        PyObject* m_copy;
    } 

    struct PyModuleDef{
        PyModuleDef_Base m_base;
        const(char)* m_name;
        const(char)* m_doc;
        Py_ssize_t m_size;
        PyMethodDef* m_methods;
        inquiry m_reload;
        traverseproc m_traverse;
        inquiry m_clear;
        freefunc m_free;
    }
}
