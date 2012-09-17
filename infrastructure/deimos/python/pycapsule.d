module deimos.python.pycapsule;

import deimos.python.object;

extern(C):
version(Python_2_7_Or_Later):
// Python-header-file: Include/pycapsule.h:

__gshared PyTypeObject PyCapsule_Type;

alias void function(PyObject*) PyCapsule_Destructor;

int PyCapsule_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyCapsule_Type;
}

PyObject* PyCapsule_New(
            void* pointer,
            const(char)* name,
            PyCapsule_Destructor destructor);

void* PyCapsule_GetPointer(PyObject* capsule, const(char)* name);

PyCapsule_Destructor PyCapsule_GetDestructor(PyObject* capsule);

const(char)* PyCapsule_GetName(PyObject* capsule);

void* PyCapsule_GetContext(PyObject* capsule);

int PyCapsule_IsValid(PyObject* capsule, const(char)* name);

int PyCapsule_SetPointer(PyObject* capsule, void* pointer);

int PyCapsule_SetDestructor(PyObject* capsule, PyCapsule_Destructor destructor);

int PyCapsule_SetName(PyObject* capsule, const(char)* name);

int PyCapsule_SetContext(PyObject* capsule, void* context);

void* PyCapsule_Import(const(char)* name, int no_block);
