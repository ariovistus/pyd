/**
  Mirror _moduleobject.h

  Module object interface
  */
module deimos.python.moduleobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.methodobject;

extern(C):
// Python-header-file: Include/moduleobject.h:

/// _
mixin(PyAPI_DATA!"PyTypeObject PyModule_Type");

// D translation of C macro:
/// _
int PyModule_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, &PyModule_Type);
}
// D translation of C macro:
/// _
int PyModule_CheckExact()(PyObject *op) {
    return Py_TYPE(op) == &PyModule_Type;
}

/// _
PyObject* PyModule_New(const(char)*);
/// _
PyObject_BorrowedRef* PyModule_GetDict(PyObject*);
/// _
const(char)* PyModule_GetName(PyObject*);
/// _
const(char)* PyModule_GetFilename(PyObject*);
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    PyObject* PyModule_GetFilenameObject(PyObject*);
}
/// _
void _PyModule_Clear(PyObject*);

version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    PyModuleDef* PyModule_GetDef(PyObject*);
    /// Availability: 3.*
    void* PyModule_GetState(PyObject*);

    /// subclass of PyObject
    /// Availability: 3.*
    struct PyModuleDef_Base {
        mixin PyObject_HEAD;
        /// _
        PyObject* function() m_init;
        /// _
        Py_ssize_t m_index;
        /// _
        PyObject* m_copy;
    }

    version(Python_3_5_Or_Later) {
        struct PyModuleDef_Slot {
            int slot;
            void* value;
        }

        enum Py_mod_create = 1;
        enum Py_mod_exec = 2;
    }

    /// Availability: 3.*
    struct PyModuleDef{
        /// _
        PyModuleDef_Base m_base;
        /// _
        const(char)* m_name;
        /// _
        const(char)* m_doc;
        /// _
        Py_ssize_t m_size;
        /// _
        PyMethodDef* m_methods;
        version(Python_3_5_Or_Later) {
            /// _
            PyModuleDef_Slot* m_slots;
        }else{
            /// _
            inquiry m_reload;
        }
        /// _
        traverseproc m_traverse;
        /// _
        inquiry m_clear;
        /// _
        freefunc m_free;
    }
}
