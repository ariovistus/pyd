module python2.moduleobject;

import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/moduleobject.h:

__gshared PyTypeObject PyModule_Type;

// D translation of C macro:
int PyModule_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, &PyModule_Type);
}
// D translation of C macro:
int PyModule_CheckExact()(PyObject *op) {
    return Py_TYPE(op) == &PyModule_Type;
}

PyObject* PyModule_New(Char1*);
PyObject_BorrowedRef* PyModule_GetDict(PyObject*);
char* PyModule_GetName(PyObject*);
char* PyModule_GetFilename(PyObject*);
void _PyModule_Clear(PyObject*);

