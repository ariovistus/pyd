module python2.descrobject;

import python2.types;
import python2.object;
import python2.methodobject;
import python2.structmember;

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

struct PyMethodDescrObject {
    mixin PyDescr_COMMON;
    PyMethodDef* d_method;
}

struct PyMemberDescrObject {
    mixin PyDescr_COMMON;
    PyMemberDef* d_member;
}

struct PyGetSetDescrObject {
    mixin PyDescr_COMMON;
    PyGetSetDef* d_getset;
}

struct PyWrapperDescrObject {
    mixin PyDescr_COMMON;
    wrapperbase* d_base;
    void* d_wrapped;
}

// PyWrapperDescr_Type is currently not accessible from D.
__gshared PyTypeObject PyWrapperDescr_Type;
version(Python_2_6_Or_Later){
    __gshared PyTypeObject PyDictProxy_Type;
    __gshared PyTypeObject PyGetSetDescr_Type;
    __gshared PyTypeObject PyMemberDescr_Type;
}

PyObject* PyDescr_NewMethod(PyTypeObject*, PyMethodDef*);
PyObject* PyDescr_NewClassMethod(PyTypeObject*, PyMethodDef*);
PyObject* PyDescr_NewMember(PyTypeObject*, PyMemberDef*);
PyObject* PyDescr_NewGetSet(PyTypeObject*, PyGetSetDef*);
PyObject* PyDescr_NewWrapper(PyTypeObject*, wrapperbase*, void*);
PyObject* PyDictProxy_New(PyObject*);
PyObject* PyWrapper_New(PyObject*, PyObject*);

__gshared PyTypeObject PyProperty_Type;


