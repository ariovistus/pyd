module deimos.python.methodobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/methodobject.h:

__gshared PyTypeObject PyCFunction_Type;

// D translation of C macro:
int PyCFunction_Check()(PyObject *op) {
    return Py_TYPE(op) == &PyCFunction_Type;
}

alias PyObject* function(PyObject*, PyObject*) PyCFunction;
alias PyObject* function(PyObject*, PyObject*,PyObject*) PyCFunctionWithKeywords;
alias PyObject* function(PyObject*) PyNoArgsFunction;

PyCFunction PyCFunction_GetFunction(PyObject*);
// TODO: returns borrowed ref?
PyObject* PyCFunction_GetSelf(PyObject*);
int PyCFunction_GetFlags(PyObject*);

PyObject* PyCFunction_Call(PyObject*, PyObject*, PyObject*);

struct PyMethodDef {
    Char1*	ml_name;
    PyCFunction  ml_meth;
    int		 ml_flags;
    Char1*	ml_doc;
}

version(Python_3_0_Or_Later) {
}else{
    // TODO: returns borrowed ref?
    PyObject* Py_FindMethod(PyMethodDef*, PyObject*, Char1*);
}
PyObject* PyCFunction_NewEx(PyMethodDef*, PyObject*,PyObject*);
PyObject* PyCFunction_New()(PyMethodDef* ml, PyObject* self) {
    return PyCFunction_NewEx(ml, self, null);
}

enum int METH_OLDARGS = 0x0000;
enum int METH_VARARGS = 0x0001;
enum int METH_KEYWORDS= 0x0002;
enum int METH_NOARGS  = 0x0004;
enum int METH_O       = 0x0008;
enum int METH_CLASS   = 0x0010;
enum int METH_STATIC  = 0x0020;
enum int METH_COEXIST = 0x0040;

version(Python_3_0_Or_Later) {
}else{
    struct PyMethodChain {
        PyMethodDef *methods;
        PyMethodChain *link;
    }

    PyObject* Py_FindMethodInChain(PyMethodChain*, PyObject*, Char1*);
}

struct PyCFunctionObject {
    mixin PyObject_HEAD;

    PyMethodDef* m_ml;
    PyObject*    m_self;
    PyObject*    m_module;
}

version(Python_2_6_Or_Later){
    int PyCFunction_ClearFreeList();
}


