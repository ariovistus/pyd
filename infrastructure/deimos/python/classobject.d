/**
  Mirror _classobject.h
  */
module deimos.python.classobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/classobject.h:

version(Python_3_0_Or_Later) {
}else{
    /**
subclasses PyObject

Availability: 2.*
    */
    struct PyClassObject {
        mixin PyObject_HEAD;

        /** A tuple of class objects */
        PyObject*	cl_bases;
        /** A dictionary */
        PyObject*	cl_dict;
        /** A string */
        PyObject*	cl_name;
        /** The following three are functions or null */
        PyObject*	cl_getattr;
        /// ditto
        PyObject*	cl_setattr;
        /// ditto
        PyObject*	cl_delattr;
    }

    /// subclass of PyObject.
    /// Availability: 2.*
    struct PyInstanceObject {
        mixin PyObject_HEAD;

        /** The class object */
        PyClassObject* in_class;
        /** A dictionary */
        PyObject*	  in_dict;
        /** List of weak references */
        PyObject*	  in_weakreflist;
    }
}

/// subclasses PyObject.
struct PyMethodObject {
    mixin PyObject_HEAD;
    /** The callable object implementing the method */
    PyObject* im_func;
    /** The instance it is bound to, or NULL */
    PyObject* im_self;
    version(Python_3_0_Or_Later) {
    }else{
        /** The class that asked for the method
        Availability: 2.*
         */
        PyObject* im_class;
    }
    /** List of weak references */
    PyObject* im_weakreflist;
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PyMethod_Type");

// D translation of C macro:
int PyMethod_Check()(PyObject *op) {
    return Py_TYPE(op) == &PyMethod_Type;
}

version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    PyObject* PyMethod_New(PyObject*, PyObject*);
}else{
    /// Availability: 2.*
    mixin(PyAPI_DATA!"PyTypeObject PyClass_Type");
    /// Availability: 2.*
    mixin(PyAPI_DATA!"PyTypeObject PyInstance_Type");
    // D translation of C macro:
    /// Availability: 2.*
    int PyClass_Check()(PyObject *op) {
        return Py_TYPE(op) == &PyClass_Type;
    }

    // D translation of C macro:
    /// Availability: 2.*
    int PyInstance_Check()(PyObject *op) {
        return Py_TYPE(op) == &PyInstance_Type;
    }

    /// Availability: 2.*
    PyObject* PyClass_New(PyObject*, PyObject*, PyObject*);
    /// Availability: 2.*
    PyObject* PyInstance_New(PyObject*, PyObject*, PyObject*);
    /// Availability: 2.*
    PyObject* PyInstance_NewRaw(PyObject*, PyObject*);
    /// Availability: 2.*
    PyObject* PyMethod_New(PyObject*, PyObject*, PyObject*);
    /// Availability: 2.*
    PyObject_BorrowedRef* PyMethod_Class(PyObject*);
/** Look up attribute with name (a string) on instance object pinst, using
 * only the instance and base class dicts.  If a descriptor is found in
 * a class dict, the descriptor is returned without calling it.
 * Returns NULL if nothing found, else a borrowed reference to the
 * value associated with name in the dict in which name was found.
 * The point of this routine is that it never calls arbitrary Python
 * code, so is always "safe":  all it does is dict lookups.  The function
 * can't fail, never sets an exception, and NULL is not an error (it just
 * means "not found").
 */
    /// Availability: 2.*
    PyObject* _PyInstance_Lookup(PyObject* pinst, PyObject* name);
    /// Availability: 2.*
    PyObject_BorrowedRef* PyMethod_GET_CLASS()(PyObject* meth) {
        return borrowed((cast(PyMethodObject*)meth).im_class);
    }
    /// Availability: 2.*
    int PyClass_IsSubclass(PyObject*, PyObject*);
}

/// _
PyObject_BorrowedRef* PyMethod_Function(PyObject*);
/// _
PyObject_BorrowedRef* PyMethod_Self(PyObject*);
/// _
PyObject_BorrowedRef* PyMethod_GET_FUNCTION()(PyObject* meth) {
    return (cast(PyMethodObject*)meth).im_func;
}
/// _
PyObject_BorrowedRef* PyMethod_GET_SELF()(PyObject* meth) {
    return (cast(PyMethodObject*)meth).im_self;
}

version(Python_2_6_Or_Later){
    /// Availability: >= 2.6
    int PyMethod_ClearFreeList();
}

version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    struct PyInstanceMethodObject{
        mixin PyObject_HEAD;
        PyObject *func;
    }

    /// Availability: 3.*
    mixin(PyAPI_DATA!"PyTypeObject PyInstanceMethod_Type");

    /// Availability: 3.*
    int PyInstanceMethod_Check()(PyObject* op) {
        return (op.ob_type is &PyInstanceMethod_Type);
    }

    /// Availability: 3.*
    PyObject* PyInstanceMethod_New(PyObject*);
    /// Availability: 3.*
    PyObject* PyInstanceMethod_Function(PyObject*);

    /** Macros for direct access to these values. Type checks are *not*
       done, so use with care. */
    /// Availability: 3.*
    PyObject* PyInstanceMethod_GET_FUNCTION()(PyObject* meth) {
        return ((cast(PyInstanceMethodObject*)meth).func);
    }
}


