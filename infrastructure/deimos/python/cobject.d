/**
  Mirror _cobject.h

   C objects to be exported from one extension module to another.

   C objects are used for communication between extension modules.
   They provide a way for an extension module to export a C interface
   to other extension modules, so that extension modules can use the
   Python import mechanism to link to one another.

  Note CObjects are pending deprecation in 2.7 and gone in 3.2.
  It is recommended you switch all use of CObjects to capsules.

See_Also:
   <a href="pycapsule.html"> pycapsule.d </a> $(BR)
   <a href="http://docs.python.org/c-api/capsule.html"> Capsules </a>
  */
module deimos.python.cobject;

import deimos.python.pyport;
import deimos.python.object;

version(Python_3_2_Or_Later) {
    // cobject.h not in python 3
}else {
extern(C):
// Python-header-file: Include/cobject.h:

// PyCObject_Type is a Python type for transporting an arbitrary C pointer
// from the C level to Python and back (in essence, an opaque handle).

/// Availaibility: 2.*, 3.0, 3.1
mixin(PyAPI_DATA!"PyTypeObject PyCObject_Type");

// D translation of C macro:
/// Availaibility: 2.*, 3.0, 3.1
int PyCObject_Check()(PyObject *op) {
    return Py_TYPE(op) == &PyCObject_Type;
}

/// Availaibility: 2.*, 3.0, 3.1
PyObject* PyCObject_FromVoidPtr(void* cobj, void function(void*) destruct);
/// Availaibility: 2.*, 3.0, 3.1
PyObject* PyCObject_FromVoidPtrAndDesc(void* cobj, void* desc,
        void function(void*,void*) destruct);
/// Availaibility: 2.*, 3.0, 3.1
void* PyCObject_AsVoidPtr(PyObject*);
/// Availaibility: 2.*, 3.0, 3.1
void* PyCObject_GetDesc(PyObject*);
/// Availaibility: 2.*, 3.0, 3.1
void* PyCObject_Import(const(char)* module_name, const(char)* cobject_name);
/// Availaibility: 2.*, 3.0, 3.1
int PyCObject_SetVoidPtr(PyObject* self, void* cobj);

version(Python_2_6_Or_Later){
    /// subclass of PyObject.
    /// Availaibility: 2.6, 2.7, 3.0, 3.1
    struct PyCObject {
        mixin PyObject_HEAD;
        void* cobject;
        void* desc;
        void function(void*) destructor;
    };
}


}
