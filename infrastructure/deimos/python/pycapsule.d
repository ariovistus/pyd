/**
  Mirror _pycapsule.h

  Capsule objects let you wrap a C "void *" pointer in a Python
  object.  They're a way of passing data through the Python interpreter
  without creating your own custom type.

  Capsules are used for communication between extension modules.
  They provide a way for an extension module to export a C interface
  to other extension modules, so that extension modules can use the
  Python import mechanism to link to one another.

  This was introduced in python 2.7

See_Also:
   <a href="http://docs.python.org/c-api/capsule.html"> Capsules </a>
  */
module deimos.python.pycapsule;

import deimos.python.pyport;
import deimos.python.object;

version(Python_3_1_Or_Later) {
    version = PyCapsule;
}else version(Python_3_0_Or_Later) {
}else version(Python_2_7_Or_Later) {
    version = PyCapsule;
}

version(PyCapsule) {
extern(C):
// Python-header-file: Include/pycapsule.h:

/// Availability: >= 2.7
mixin(PyAPI_DATA!"PyTypeObject PyCapsule_Type");

/// Availability: >= 2.7
alias void function(PyObject*) PyCapsule_Destructor;

/// Availability: >= 2.7
int PyCapsule_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyCapsule_Type;
}

/// Availability: >= 2.7
PyObject* PyCapsule_New(
            void* pointer,
            const(char)* name,
            PyCapsule_Destructor destructor);

/// Availability: >= 2.7
void* PyCapsule_GetPointer(PyObject* capsule, const(char)* name);

/// Availability: >= 2.7
PyCapsule_Destructor PyCapsule_GetDestructor(PyObject* capsule);

/// Availability: >= 2.7
const(char)* PyCapsule_GetName(PyObject* capsule);

/// Availability: >= 2.7
void* PyCapsule_GetContext(PyObject* capsule);

/// Availability: >= 2.7
int PyCapsule_IsValid(PyObject* capsule, const(char)* name);

/// Availability: >= 2.7
int PyCapsule_SetPointer(PyObject* capsule, void* pointer);

/// Availability: >= 2.7
int PyCapsule_SetDestructor(PyObject* capsule, PyCapsule_Destructor destructor);

/// Availability: >= 2.7
int PyCapsule_SetName(PyObject* capsule, const(char)* name);

/// Availability: >= 2.7
int PyCapsule_SetContext(PyObject* capsule, void* context);

/// Availability: >= 2.7
void* PyCapsule_Import(const(char)* name, int no_block);
}
