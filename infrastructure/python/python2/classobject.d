module python2.classobject;

import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/classobject.h:

struct PyClassObject {
    mixin PyObject_HEAD;

    PyObject*	cl_bases;	/* A tuple of class objects */
    PyObject*	cl_dict;	/* A dictionary */
    PyObject*	cl_name;	/* A string */
    /* The following three are functions or null */
    PyObject*	cl_getattr;
    PyObject*	cl_setattr;
    PyObject*	cl_delattr;
}

struct PyInstanceObject {
    mixin PyObject_HEAD;

    PyClassObject* in_class;
    PyObject*	  in_dict;
    PyObject*	  in_weakreflist;
}

struct PyMethodObject {
    mixin PyObject_HEAD;

    PyObject* im_func;
    PyObject* im_self;
    PyObject* im_class;
    PyObject* im_weakreflist;
}

__gshared PyTypeObject PyClass_Type, PyInstance_Type, PyMethod_Type;

// D translation of C macro:
int PyClass_Check()(PyObject *op) {
    return Py_TYPE(op) == &PyClass_Type;
}

// D translation of C macro:
int PyInstance_Check()(PyObject *op) {
    return Py_TYPE(op) == &PyInstance_Type;
}

// &PyMethod_Type is accessible via PyMethod_Type_p.
// D translation of C macro:
int PyMethod_Check()(PyObject *op) {
    return Py_TYPE(op) == &PyMethod_Type;
}

PyObject* PyClass_New(PyObject*, PyObject*, PyObject*);
PyObject* PyInstance_New(PyObject*, PyObject*, PyObject*);
PyObject* PyInstance_NewRaw(PyObject*, PyObject*);
PyObject* PyMethod_New(PyObject*, PyObject*, PyObject*);

PyObject_BorrowedRef* PyMethod_Function(PyObject*);
PyObject_BorrowedRef* PyMethod_Self(PyObject*);
PyObject_BorrowedRef* PyMethod_Class(PyObject*);

PyObject* _PyInstance_Lookup(PyObject* pinst, PyObject* name);

PyObject_BorrowedRef* PyMethod_GET_FUNCTION()(PyObject* meth) {
    return (cast(PyMethodObject*)meth).im_func;
}
PyObject_BorrowedRef* PyMethod_GET_SELF()(PyObject* meth) {
    return (cast(PyMethodObject*)meth).im_self;
}
PyObject_BorrowedRef* PyMethod_GET_CLASS()(PyObject* meth) {
    return cast(PyObject_BorrowedRef*)(cast(PyMethodObject*)meth).im_class;
}

int PyClass_IsSubclass(PyObject*, PyObject*);

version(Python_2_6_Or_Later){
    int PyMethod_ClearFreeList();
}


