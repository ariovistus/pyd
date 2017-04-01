/**
  Mirror _methodobject.h

Method object interface
  */
module deimos.python.methodobject;

import core.stdc.stdio;
import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/methodobject.h:

/** This is about the type 'builtin_function_or_method',
   not Python methods in user-defined classes.  See classobject.h
   for the latter. */
mixin(PyAPI_DATA!"PyTypeObject PyCFunction_Type");

// D translation of C macro:
/// _
int PyCFunction_Check()(PyObject *op) {
    return Py_TYPE(op) == &PyCFunction_Type;
}

/// _
alias PyObject* function(PyObject*, PyObject*) PyCFunction;
/// _
alias PyObject* function(PyObject*, PyObject*,PyObject*) PyCFunctionWithKeywords;
/// _
alias PyObject* function(PyObject*) PyNoArgsFunction;

/// _
PyCFunction PyCFunction_GetFunction(PyObject*);
// TODO: returns borrowed ref?
/// _
PyObject* PyCFunction_GetSelf(PyObject*);
/// _
int PyCFunction_GetFlags(PyObject*);
/** Macros for direct access to these values. Type checks are *not*
   done, so use with care. */
auto PyCFunction_GET_FUNCTION()(PyObject* func) {
    return (cast(PyCFunctionObject*)func).m_ml.ml_meth;
}
/// ditto
auto PyCFunction_GET_SELF()(PyObject* func) {
    return (cast(PyCFunctionObject*)func).m_self;
}
/// ditto
auto PyCFunction_GET_FLAGS(PyObject* func) {
    return (cast(PyCFunctionObject*)func).m_ml.ml_flags;
}

/// _
PyObject* PyCFunction_Call(PyObject*, PyObject*, PyObject*);

/// _
struct PyMethodDef {
    /** The name of the built-in function/method */
    const(char)*	ml_name;
    /** The C function that implements it */
    PyCFunction  ml_meth;
    /** Combination of METH_xxx flags, which mostly
      describe the args expected by the C func */
    int		 ml_flags;
    /** The __doc__ attribute, or NULL */
    const(char)*	ml_doc;
}

version(Python_3_0_Or_Later) {
}else{
    // TODO: returns borrowed ref?
    /// Availability: 2.*
    PyObject* Py_FindMethod(PyMethodDef*, PyObject*, const(char)*);
}
/// _
PyObject* PyCFunction_NewEx(PyMethodDef*, PyObject*,PyObject*);
/// _
PyObject* PyCFunction_New()(PyMethodDef* ml, PyObject* self) {
    return PyCFunction_NewEx(ml, self, null);
}

/** Flag passed to newmethodobject */
enum int METH_OLDARGS = 0x0000;
/// ditto
enum int METH_VARARGS = 0x0001;
/// ditto
enum int METH_KEYWORDS= 0x0002;
/** METH_NOARGS and METH_O must not be combined with the flags above. */
enum int METH_NOARGS  = 0x0004;
/// ditto
enum int METH_O       = 0x0008;

/** METH_CLASS and METH_STATIC are a little different; these control
   the construction of methods for a class.  These cannot be used for
   functions in modules. */
enum int METH_CLASS   = 0x0010;
/// ditto
enum int METH_STATIC  = 0x0020;
/** METH_COEXIST allows a method to be entered eventhough a slot has
   already filled the entry.  When defined, the flag allows a separate
   method, "__contains__" for example, to coexist with a defined
   slot like sq_contains. */
enum int METH_COEXIST = 0x0040;

enum int METH_FASTCALL = 0x0080;

version(Python_3_0_Or_Later) {
}else{
    /// Availability: 2.*
    struct PyMethodChain {
        /** Methods of this type */
        PyMethodDef *methods;
        /** NULL or base type */
        PyMethodChain *link;
    }

    /// Availability: 2.*
    PyObject* Py_FindMethodInChain(PyMethodChain*, PyObject*, const(char)*);
}

/// subclass of PyObject
struct PyCFunctionObject {
    mixin PyObject_HEAD;

    /** Description of the C function to call */
    PyMethodDef* m_ml;
    /** Passed as 'self' arg to the C func, can be NULL */
    PyObject*    m_self;
    /** The __module__ attribute, can be anything */
    PyObject*    m_module;
    version(Python_3_5_Or_Later) {
        PyObject* m_weakreflist;
    }
}

version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    int PyCFunction_ClearFreeList();
}

version(Python_2_7_Or_Later) {
    /// Availability: >= 2.7
    void _PyCFunction_DebugMallocStats(FILE* out_);
    /// Availability: >= 2.7
    void _PyMethod_DebugMallocStats(FILE* out_);
}


