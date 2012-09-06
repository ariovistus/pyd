module python2.longobject;

import python2.types;
import python2.object;
import python2.unicodeobject;

extern(C):
// Python-header-file: Include/longobject.h:

__gshared PyTypeObject PyLong_Type;

version(Python_2_6_Or_Later){
    int PyLong_Check()(PyObject* op){
        return PyType_FastSubclass((op).ob_type, Py_TPFLAGS_LONG_SUBCLASS);
    }
}else{
    // D translation of C macro:
    int PyLong_Check()(PyObject* op) {
        return PyObject_TypeCheck(op, &PyLong_Type);
    }
}
// D translation of C macro:
int PyLong_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyLong_Type;
}

PyObject* PyLong_FromLong(C_long);
PyObject* PyLong_FromUnsignedLong(C_ulong);

PyObject* PyLong_FromLongLong(C_longlong);
PyObject* PyLong_FromUnsignedLongLong(C_ulonglong);

PyObject* PyLong_FromDouble(double);
version(Python_2_6_Or_Later){
    PyObject* PyLong_FromSize_t(size_t);
    PyObject* PyLong_FromSsize_t(Py_ssize_t);
}
PyObject* PyLong_FromVoidPtr(void*);

C_long PyLong_AsLong(PyObject*);
C_ulong PyLong_AsUnsignedLong(PyObject*);
C_ulong PyLong_AsUnsignedLongMask(PyObject*);
version(Python_2_6_Or_Later){
    Py_ssize_t PyLong_AsSsize_t(PyObject*);
}

C_longlong PyLong_AsLongLong(PyObject*);
C_ulonglong PyLong_AsUnsignedLongLong(PyObject*);
C_ulonglong PyLong_AsUnsignedLongLongMask(PyObject*);
version(Python_2_7_Or_Later) {
    C_long PyLong_AsLongAndOverflow(PyObject*, int*);
    C_longlong PyLong_AsLongLongAndOverflow(PyObject*, int*);
}

double PyLong_AsDouble(PyObject*);
PyObject*  PyLong_FromVoidPtr(void*);
void * PyLong_AsVoidPtr(PyObject*);

/**
Convert string to python long. Roughly, parses format

space* sign? space* Integer ('l'|'L')? Null

Integer: 
        '0' ('x'|'X') HexDigits
        '0' OctalDigits
        DecimalDigits  

Params:
str = null-terminated string to convert.
pend = if not null, return pointer to the terminating null character.
base = base in which string integer is encoded. possible values are 8, 
        10, 16, or 0 to autodetect base.
*/
PyObject* PyLong_FromString(char* str, char** pend, int base);
PyObject* PyLong_FromUnicode(Py_UNICODE*, int, int);
int _PyLong_Sign(PyObject* v);
size_t _PyLong_NumBits(PyObject* v);
PyObject* _PyLong_FromByteArray(
        const(ubyte)* bytes, size_t n,
        int little_endian, int is_signed);
int _PyLong_AsByteArray(PyLongObject* v,
        ubyte* bytes, size_t n,
        int little_endian, int is_signed);

version(Python_2_6_Or_Later){
    /* _PyLong_Format: Convert the long to a string object with given base,
       appending a base prefix of 0[box] if base is 2, 8 or 16.
       Add a trailing "L" if addL is non-zero.
       If newstyle is zero, then use the pre-2.6 behavior of octal having
       a leading "0", instead of the prefix "0o" */
    PyObject* _PyLong_Format(PyObject* aa, int base, int addL, int newstyle);

    /* Format the object based on the format_spec, as defined in PEP 3101
       (Advanced String Formatting). */
    PyObject*  _PyLong_FormatAdvanced(PyObject* obj,
            char *format_spec,
            Py_ssize_t format_spec_len);
}


