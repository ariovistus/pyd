/**
  Mirror _modsupport.h

  Module support interface
  */
module deimos.python.modsupport;

import core.stdc.stdio;
import deimos.python.pyport;
import deimos.python.object;
import deimos.python.methodobject;
import deimos.python.moduleobject;

extern(C):
// Python-header-file: Include/modsupport.h:

version(Python_2_5_Or_Later){
    /// _
    enum PYTHON_API_VERSION = 1013;
    /// _
    enum PYTHON_API_STRING = "1013";
}else version(Python_2_4_Or_Later){
    /// _
    enum PYTHON_API_VERSION = 1012;
    /// _
    enum PYTHON_API_STRING = "1012";
}

/// _
int PyArg_Parse(PyObject*, const(char)*, ...);
/// _
int PyArg_ParseTuple(PyObject*, const(char)*, ...);
/// _
int PyArg_ParseTupleAndKeywords(PyObject*, PyObject*,
        const(char)*, char**, ...);
/// _
int PyArg_UnpackTuple(PyObject*, const(char)*, Py_ssize_t, Py_ssize_t, ...);
/// _
PyObject * Py_BuildValue(const(char)*, ...);

/// _
int PyModule_AddObject(PyObject*, const(char)*, PyObject*);
/// _
int PyModule_AddIntConstant(PyObject*, const(char)*, C_long);
/// _
int PyModule_AddStringConstant(PyObject*, const(char)*, const(char)*);

version(Python_3_0_Or_Later) {
}else{
    version(Python_2_5_Or_Later){
        version(X86_64){
            enum Py_InitModuleSym = "Py_InitModule4_64";
        }else{
            enum Py_InitModuleSym = "Py_InitModule4";
        }
    }else{
        enum Py_InitModuleSym = "Py_InitModule4";
    }
    mixin("
            /// Availability: >= 2.5, specific to 32 or 64 bitness
            PyObject_BorrowedRef* "~Py_InitModuleSym~"(const(char) *name, PyMethodDef *methods, const(char) *doc,
        PyObject *self, int apiver);

            /// Availability: >= 2.5
            PyObject_BorrowedRef* Py_InitModule()(string name, PyMethodDef *methods)
            {
            return "~Py_InitModuleSym~"(name.ptr, methods, null,
        null, PYTHON_API_VERSION);
            }

            /// Availability: >= 2.5
            PyObject_BorrowedRef* Py_InitModule3()(string name, PyMethodDef *methods, string doc) {
            return "~Py_InitModuleSym~"(name.ptr, methods, doc.ptr, null,
        PYTHON_API_VERSION);
            }");
}


version(Python_3_0_Or_Later) {
    /// _
    enum PYTHON_ABI_VERSION = 3;
    /// _
    enum PYTHON_ABI_STRING = "3";
    /// Availability: 3.*
    PyObject* PyModule_Create2(PyModuleDef*, int apiver);

    /// Availability: 3.*
    PyObject* PyModule_Create()(PyModuleDef* modul) {
        return PyModule_Create2(modul, PYTHON_API_VERSION);
    }
}
