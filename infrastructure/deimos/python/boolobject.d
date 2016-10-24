/**
  Mirror _boolobject.h
  */
module deimos.python.boolobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.intobject;
import deimos.python.longintrepr;

extern(C):
// Python-header-file: Include/boolobject.h:

version(Python_3_0_Or_Later) {
}else{
    alias PyIntObject PyBoolObject;
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PyBool_Type");

// D translation of C macro:
/// _
int PyBool_Check()(PyObject* x) {
    return x.ob_type == &PyBool_Type;
}

version(Python_3_0_Or_Later) {
    mixin(PyAPI_DATA!"PyLongObject _Py_FalseStruct");
    mixin(PyAPI_DATA!"PyLongObject _Py_TrueStruct");
}else {
    mixin(PyAPI_DATA!"PyIntObject _Py_ZeroStruct");
    mixin(PyAPI_DATA!"PyIntObject _Py_TrueStruct");
}

/// _
@property Borrowed!PyObject* Py_True()() {
    return cast(Borrowed!PyObject*) &_Py_TrueStruct;
}
/// _
@property Borrowed!PyObject* Py_False()() {
    version(Python_3_0_Or_Later) {
        return cast(Borrowed!PyObject*) &_Py_FalseStruct;
    }else{
        return cast(Borrowed!PyObject*) &_Py_ZeroStruct;
    }
}

/** Function to return a bool from a C long */
PyObject* PyBool_FromLong(C_long);


