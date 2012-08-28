module python2.boolobject;

import python2.types;
import python2.object;
import python2.intobject;

extern(C):
// Python-header-file: Include/boolobject.h:

alias PyIntObject PyBoolObject;

__gshared PyTypeObject PyBool_Type;

// D translation of C macro:
int PyBool_Check()(PyObject* x) {
    return x.ob_type == &PyBool_Type;
}

__gshared PyIntObject _Py_ZeroStruct;
__gshared PyIntObject _Py_TrueStruct;

@property PyIntObject* Py_True()() {
    return &_Py_TrueStruct;
}
@property PyIntObject* Py_False()() {
    return &_Py_ZeroStruct;
}

PyObject* PyBool_FromLong(C_long);


