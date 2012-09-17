module deimos.python.descrobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.methodobject;
import deimos.python.structmember;

extern(C):
// Python-header-file: Include/descrobject.h:

alias PyObject* function(PyObject*, void*) getter;
alias int function(PyObject*, PyObject*, void*) setter;

struct PyGetSetDef {
    char* name;
    getter get;
    setter set;
    char* doc;
    void* closure;
}

alias PyObject* function(PyObject*, PyObject*, void*) wrapperfunc;
alias PyObject* function(PyObject*, PyObject*, void*, PyObject*) wrapperfunc_kwds;

struct wrapperbase {
    char* name;
    int offset;
    void* function_;
    wrapperfunc wrapper;
    char* doc;
    int flags;
    PyObject* name_strobj;
}

enum PyWrapperFlag_KEYWORDS = 1;

template PyDescr_COMMON() {
    mixin PyObject_HEAD;
    PyTypeObject* d_type;
    PyObject* d_name;
}

struct PyDescrObject {
    mixin PyDescr_COMMON;
}

// these were introduced in python 3, but they look generally useful.
PyTypeObject* PyDescr_TYPE(T)(T* x) 
if(     is(T == PyDescrObject) ||
        is(T == PyMethodDescrObject) ||
        is(T == PyMemberDescrObject) ||
        is(T == PyGetSetDescrObject) ||
        is(T == PyWrapperDescrObject))
{
    return ((cast(PyDescrObject*)x).d_type);
}

PyObject* PyDescr_NAME(T)(T* x) 
if(     is(T == PyDescrObject) ||
        is(T == PyMethodDescrObject) ||
        is(T == PyMemberDescrObject) ||
        is(T == PyGetSetDescrObject) ||
        is(T == PyWrapperDescrObject))
{
    return ((cast(PyDescrObject*)x).d_name);
}

struct PyMethodDescrObject {
    version(Python_3_0_Or_Later) {
        PyDescrObject d_common;
    }else {
        mixin PyDescr_COMMON;
    }
    PyMethodDef* d_method;
}

struct PyMemberDescrObject {
    version(Python_3_0_Or_Later) {
        PyDescrObject d_common;
    }else {
        mixin PyDescr_COMMON;
    }
    PyMemberDef* d_member;
}

struct PyGetSetDescrObject {
    version(Python_3_0_Or_Later) {
        PyDescrObject d_common;
    }else {
        mixin PyDescr_COMMON;
    }
    PyGetSetDef* d_getset;
}

struct PyWrapperDescrObject {
    version(Python_3_0_Or_Later) {
        PyDescrObject d_common;
    }else {
        mixin PyDescr_COMMON;
    }
    wrapperbase* d_base;
    void* d_wrapped;
}

// PyWrapperDescr_Type is currently not accessible from D.
__gshared PyTypeObject PyWrapperDescr_Type;
version(Python_2_6_Or_Later) {
    __gshared PyTypeObject PyDictProxy_Type;
    __gshared PyTypeObject PyGetSetDescr_Type;
    __gshared PyTypeObject PyMemberDescr_Type;
}
version(Python_3_0_Or_Later) {
    __gshared PyTypeObject PyClassMethodDescr_Type;
    __gshared PyTypeObject PyMethodDescr_Type;
    __gshared PyTypeObject _PyMethodWrapper_Type;
}

PyObject* PyDescr_NewMethod(PyTypeObject*, PyMethodDef*);
PyObject* PyDescr_NewClassMethod(PyTypeObject*, PyMethodDef*);
PyObject* PyDescr_NewMember(PyTypeObject*, PyMemberDef*);
PyObject* PyDescr_NewGetSet(PyTypeObject*, PyGetSetDef*);
PyObject* PyDescr_NewWrapper(PyTypeObject*, wrapperbase*, void*);
PyObject* PyDictProxy_New(PyObject*);
PyObject* PyWrapper_New(PyObject*, PyObject*);

__gshared PyTypeObject PyProperty_Type;


