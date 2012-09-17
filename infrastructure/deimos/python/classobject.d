module deimos.python.classobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/classobject.h:

version(Python_3_0_Or_Later) {
}else{
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
}

struct PyMethodObject {
    mixin PyObject_HEAD;

    PyObject* im_func;
    PyObject* im_self;
    version(Python_3_0_Or_Later) {
    }else{
        PyObject* im_class;
    }
    PyObject* im_weakreflist;
}

__gshared PyTypeObject PyMethod_Type;

// D translation of C macro:
int PyMethod_Check()(PyObject *op) {
    return Py_TYPE(op) == &PyMethod_Type;
}

version(Python_3_0_Or_Later) {
    PyObject* PyMethod_New(PyObject*, PyObject*);
}else{
    __gshared PyTypeObject PyClass_Type;
    __gshared PyTypeObject PyInstance_Type;
    // D translation of C macro:
    int PyClass_Check()(PyObject *op) {
        return Py_TYPE(op) == &PyClass_Type;
    }

    // D translation of C macro:
    int PyInstance_Check()(PyObject *op) {
        return Py_TYPE(op) == &PyInstance_Type;
    }

    PyObject* PyClass_New(PyObject*, PyObject*, PyObject*);
    PyObject* PyInstance_New(PyObject*, PyObject*, PyObject*);
    PyObject* PyInstance_NewRaw(PyObject*, PyObject*);
    PyObject* PyMethod_New(PyObject*, PyObject*, PyObject*);
    PyObject_BorrowedRef* PyMethod_Class(PyObject*);
    PyObject* _PyInstance_Lookup(PyObject* pinst, PyObject* name);
    PyObject_BorrowedRef* PyMethod_GET_CLASS()(PyObject* meth) {
        return borrowed((cast(PyMethodObject*)meth).im_class);
    }
    int PyClass_IsSubclass(PyObject*, PyObject*);
}

PyObject_BorrowedRef* PyMethod_Function(PyObject*);
PyObject_BorrowedRef* PyMethod_Self(PyObject*);

PyObject_BorrowedRef* PyMethod_GET_FUNCTION()(PyObject* meth) {
    return (cast(PyMethodObject*)meth).im_func;
}
PyObject_BorrowedRef* PyMethod_GET_SELF()(PyObject* meth) {
    return (cast(PyMethodObject*)meth).im_self;
}

version(Python_2_6_Or_Later){
    int PyMethod_ClearFreeList();
}

version(Python_3_0_Or_Later) {
    struct PyInstanceMethodObject{
        mixin PyObject_HEAD;
        PyObject *func;
    }

    __gshared PyTypeObject PyInstanceMethod_Type;

    int PyInstanceMethod_Check()(PyObject* op) {
        return (op.ob_type is &PyInstanceMethod_Type);
    }

    PyObject* PyInstanceMethod_New(PyObject*);
    PyObject* PyInstanceMethod_Function(PyObject*);

    /* Macros for direct access to these values. Type checks are *not*
       done, so use with care. */
    PyObject* PyInstanceMethod_GET_FUNCTION()(PyObject* meth) {
        return ((cast(PyInstanceMethodObject*)meth).func);
    }
}


