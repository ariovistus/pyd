module deimos.python.intobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.unicodeobject;

version(Python_3_0_Or_Later) {
    // int merged with long in python 3
}else {
extern(C):
// Python-header-file: Include/intobject.h:

struct PyIntObject {
    mixin PyObject_HEAD;

    C_long ob_ival;
}

__gshared PyTypeObject PyInt_Type;

// D translation of C macro:
int PyInt_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, &PyInt_Type);
}
// D translation of C macro:
int PyInt_CheckExact()(PyObject* op) {
    return op.ob_type == &PyInt_Type;
}

PyObject* PyInt_FromString(char*, char**, int);
PyObject* PyInt_FromUnicode(Py_UNICODE*, Py_ssize_t, int);
PyObject* PyInt_FromLong(C_long);
version(Python_2_5_Or_Later){
    PyObject* PyInt_FromSize_t(size_t);
    PyObject* PyInt_FromSsize_t(Py_ssize_t);

    Py_ssize_t PyInt_AsSsize_t(PyObject*);
}

C_long PyInt_AsLong(PyObject*);
C_ulong PyInt_AsUnsignedLongMask(PyObject*);
C_ulonglong PyInt_AsUnsignedLongLongMask(PyObject*);

C_long PyInt_GetMax(); /* Accessible at the Python level as sys.maxint */

C_ulong PyOS_strtoul(char*, char**, int);
C_long PyOS_strtol(char*, char**, int);
version(Python_2_6_Or_Later){
    C_long PyOS_strtol(char*, char**, int);

    /* free list api */
    int PyInt_ClearFreeList();

    /* Convert an integer to the given base.  Returns a string.
       If base is 2, 8 or 16, add the proper prefix '0b', '0o' or '0x'.
       If newstyle is zero, then use the pre-2.6 behavior of octal having
       a leading "0" */
    PyObject* _PyInt_Format(PyIntObject* v, int base, int newstyle);

    /* Format the object based on the format_spec, as defined in PEP 3101
       (Advanced String Formatting). */
    PyObject*  _PyInt_FormatAdvanced(PyObject* obj,
            char* format_spec,
            Py_ssize_t format_spec_len);
}


}
