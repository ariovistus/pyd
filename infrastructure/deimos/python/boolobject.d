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

__gshared PyTypeObject PyBool_Type;

// D translation of C macro:
int PyBool_Check()(PyObject* x) {
    return x.ob_type == &PyBool_Type;
}

version(Python_3_0_Or_Later) {
    __gshared PyLongObject _Py_FalseStruct;
    __gshared PyLongObject _Py_TrueStruct;
}else {
    __gshared PyIntObject _Py_ZeroStruct;
    __gshared PyIntObject _Py_TrueStruct;
}

@property Borrowed!PyObject* Py_True()() {
    return cast(Borrowed!PyObject*) &_Py_TrueStruct;
}
@property Borrowed!PyObject* Py_False()() {
    version(Python_3_0_Or_Later) {
        return cast(Borrowed!PyObject*) &_Py_FalseStruct;
    }else{
        return cast(Borrowed!PyObject*) &_Py_ZeroStruct;
    }
}

PyObject* PyBool_FromLong(C_long);


