module deimos.python.modsupport;

import std.c.stdio;
import deimos.python.pyport;
import deimos.python.object;
import deimos.python.methodobject;
import deimos.python.moduleobject;

extern(C):
// Python-header-file: Include/modsupport.h:

version(Python_2_5_Or_Later){
    enum PYTHON_API_VERSION = 1013;
    enum PYTHON_API_STRING = "1013";
}else version(Python_2_4_Or_Later){
    enum PYTHON_API_VERSION = 1012;
    enum PYTHON_API_STRING = "1012";
}

int PyArg_Parse(PyObject*, Char1*, ...);
int PyArg_ParseTuple(PyObject*, Char1*, ...);
int PyArg_ParseTupleAndKeywords(PyObject*, PyObject*,
        Char1*, char**, ...);
int PyArg_UnpackTuple(PyObject*, Char1*, Py_ssize_t, Py_ssize_t, ...);
PyObject * Py_BuildValue(Char1*, ...);

int PyModule_AddObject(PyObject*, Char1*, PyObject*);
int PyModule_AddIntConstant(PyObject*, Char1*, C_long);
int PyModule_AddStringConstant(PyObject*, Char1*, Char1*);

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
    mixin("PyObject_BorrowedRef* "~Py_InitModuleSym~"(Char1 *name, PyMethodDef *methods, Char1 *doc,
        PyObject *self, int apiver);

            PyObject_BorrowedRef* Py_InitModule()(string name, PyMethodDef *methods)
            {
            return "~Py_InitModuleSym~"(cast(Char1*) name.ptr, methods, cast(Char1 *)(null),
        cast(PyObject *)(null), PYTHON_API_VERSION);
            }

            PyObject_BorrowedRef* Py_InitModule3()(string name, PyMethodDef *methods, string doc) {
            return "~Py_InitModuleSym~"(cast(Char1*)name.ptr, methods, cast(Char1*) doc, cast(PyObject *)null,
        PYTHON_API_VERSION);
            }");
}


version(Python_3_0_Or_Later) {
    enum PYTHON_ABI_VERSION = 3;
    enum PYTHON_ABI_STRING = "3";
    PyObject* PyModule_Create2(PyModuleDef*, int apiver);

    PyObject* PyModule_Create()(PyModuleDef* modul) {
        return PyModule_Create2(modul, PYTHON_API_VERSION);
    }
}
