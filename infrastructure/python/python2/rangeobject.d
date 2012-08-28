module python2.rangeobject;

import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/rangeobject.h:

// &PyRange_Type is accessible via PyRange_Type_p.
__gshared PyTypeObject PyRange_Type;

// D translation of C macro:
int PyRange_Check()(PyObject *op) {
    return Py_TYPE(op) == &PyRange_Type;
}

version(Python_2_5_Or_Later){
    // Removed in 2.5
}else{
    PyObject* PyRange_New(C_long, C_long, C_long, int);
}


