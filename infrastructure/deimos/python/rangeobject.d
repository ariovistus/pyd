module deimos.python.rangeobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/rangeobject.h:

__gshared PyTypeObject PyRange_Type;
__gshared PyTypeObject PyRangeIter_Type;
__gshared PyTypeObject PyLongRangeIter_Type;

// D translation of C macro:
int PyRange_Check()(PyObject *op) {
    return Py_TYPE(op) == &PyRange_Type;
}

version(Python_2_5_Or_Later){
    // Removed in 2.5
}else{
    PyObject* PyRange_New(C_long, C_long, C_long, int);
}


