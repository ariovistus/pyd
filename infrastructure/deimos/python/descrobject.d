/**
  Mirror _descrobject.h
  */
module deimos.python.descrobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.methodobject;
import deimos.python.structmember;

extern(C):
// Python-header-file: Include/descrobject.h:

/// _
alias PyObject* function(PyObject*, void*) getter;
/// _
alias int function(PyObject*, PyObject*, void*) setter;

/// _
struct PyGetSetDef {
    /// _
    char* name;
    /// ditto
    getter get;
    /// ditto
    setter set;
    /// ditto
    char* doc;
    /// ditto
    void* closure;
}

/// _
alias PyObject* function(PyObject*, PyObject*, void*) wrapperfunc;
/// _
alias PyObject* function(PyObject*, PyObject*, void*, PyObject*) wrapperfunc_kwds;

/// _
struct wrapperbase {
    /// _
    char* name;
    /// ditto
    int offset;
    /// ditto
    void* function_;
    /// ditto
    wrapperfunc wrapper;
    /// ditto
    char* doc;
    /// ditto
    int flags;
    /// ditto
    PyObject* name_strobj;
}

/// _
enum PyWrapperFlag_KEYWORDS = 1;

/// _
template PyDescr_COMMON() {
    version(Python_3_0_Or_Later) {
        /// _
        PyDescrObject d_common;
    }else{
        mixin PyObject_HEAD;
        /// _
        PyTypeObject* d_type;
        /// _
        PyObject* d_name;
    }
}

/// subclass of PyObject.
struct PyDescrObject {
    version(Python_3_0_Or_Later) {
        mixin PyObject_HEAD;
        /// _
        PyTypeObject* d_type;
        /// _
        PyObject* d_name;
    }else{
        mixin PyDescr_COMMON;
    }
}

/// introduced in python 3, but looks generally useful.
PyTypeObject* PyDescr_TYPE(T)(T* x)
if(     is(T == PyDescrObject) ||
        is(T == PyMethodDescrObject) ||
        is(T == PyMemberDescrObject) ||
        is(T == PyGetSetDescrObject) ||
        is(T == PyWrapperDescrObject))
{
    return ((cast(PyDescrObject*)x).d_type);
}

/// introduced in python 3, but looks generally useful.
PyObject* PyDescr_NAME(T)(T* x)
if(     is(T == PyDescrObject) ||
        is(T == PyMethodDescrObject) ||
        is(T == PyMemberDescrObject) ||
        is(T == PyGetSetDescrObject) ||
        is(T == PyWrapperDescrObject))
{
    return ((cast(PyDescrObject*)x).d_name);
}

/// subclass of PyDescrObject
struct PyMethodDescrObject {
    mixin PyDescr_COMMON;
    /// _
    PyMethodDef* d_method;
}

/// subclass of PyDescrObject
struct PyMemberDescrObject {
    mixin PyDescr_COMMON;
    /// _
    PyMemberDef* d_member;
}

/// subclass of PyDescrObject
struct PyGetSetDescrObject {
    mixin PyDescr_COMMON;
    /// _
    PyGetSetDef* d_getset;
}

/// subclass of PyDescrObject
struct PyWrapperDescrObject {
    mixin PyDescr_COMMON;
    /// _
    wrapperbase* d_base;
    /** This can be any function pointer */
    void* d_wrapped;
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PyWrapperDescr_Type");
version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    mixin(PyAPI_DATA!"PyTypeObject PyDictProxy_Type");
    /// Availability: >= 2.6
    mixin(PyAPI_DATA!"PyTypeObject PyGetSetDescr_Type");
    /// Availability: >= 2.6
    mixin(PyAPI_DATA!"PyTypeObject PyMemberDescr_Type");
}
version(Python_3_0_Or_Later) {
    /// Availability: 3.2
    mixin(PyAPI_DATA!"PyTypeObject PyClassMethodDescr_Type");
    /// Availability: 3.2
    mixin(PyAPI_DATA!"PyTypeObject PyMethodDescr_Type");
    /// Availability: 3.2
    mixin(PyAPI_DATA!"PyTypeObject _PyMethodWrapper_Type");
}

/// _
PyObject* PyDescr_NewMethod(PyTypeObject*, PyMethodDef*);
/// _
PyObject* PyDescr_NewClassMethod(PyTypeObject*, PyMethodDef*);
/// _
PyObject* PyDescr_NewMember(PyTypeObject*, PyMemberDef*);
/// _
PyObject* PyDescr_NewGetSet(PyTypeObject*, PyGetSetDef*);
/// _
PyObject* PyDescr_NewWrapper(PyTypeObject*, wrapperbase*, void*);
/// _
PyObject* PyDictProxy_New(PyObject*);
/// _
PyObject* PyWrapper_New(PyObject*, PyObject*);

/// _
mixin(PyAPI_DATA!"PyTypeObject PyProperty_Type");


