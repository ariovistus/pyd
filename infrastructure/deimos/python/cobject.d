module deimos.python.cobject;

import deimos.python.pyport;
import deimos.python.object;

version(Python_3_0_Or_Later) {
    // cobject.h not in python 3
}else {
extern(C):
// Python-header-file: Include/cobject.h:

// PyCObject_Type is a Python type for transporting an arbitrary C pointer
// from the C level to Python and back (in essence, an opaque handle).

__gshared PyTypeObject PyCObject_Type;

// D translation of C macro:
int PyCObject_Check()(PyObject *op) {
    return Py_TYPE(op) == &PyCObject_Type;
}

PyObject* PyCObject_FromVoidPtr(void* cobj, void function(void*) destruct);
PyObject* PyCObject_FromVoidPtrAndDesc(void* cobj, void* desc,
        void function(void*,void*) destruct);
void* PyCObject_AsVoidPtr(PyObject*);
void* PyCObject_GetDesc(PyObject*);
void* PyCObject_Import(const(char)* module_name, const(char)* cobject_name);
int PyCObject_SetVoidPtr(PyObject* self, void* cobj);

version(Python_2_6_Or_Later){
    struct PyCObject {
        mixin PyObject_HEAD;
        void* cobject;
        void* desc;
        void function(void*) destructor;
    };
}


}
