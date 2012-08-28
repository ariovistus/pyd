module python2.stringobject;

import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/stringobject.h:

struct PyStringObject {
    mixin PyObject_VAR_HEAD;

    C_long ob_shash;
    int ob_sstate;
    // DSR:XXX:LAYOUT:
    // Will the D layout for a 1-char array be the same as the C layout?  I
    // think the D array will be larger.
    char _ob_sval[1];
    char* ob_sval()() {
        return _ob_sval.ptr;
    }
}

// &PyBaseString_Type is accessible via PyBaseString_Type_p.
__gshared PyTypeObject PyBaseString_Type;
__gshared PyTypeObject PyString_Type;

// D translation of C macro:
int PyString_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, &PyString_Type);
}
// D translation of C macro:
int PyString_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyString_Type;
}

PyObject* PyString_FromStringAndSize(const(char)*, Py_ssize_t);
PyObject* PyString_FromString(const(char)*);
// PyString_FromFormatV omitted
PyObject* PyString_FromFormat(const(char)*, ...);
Py_ssize_t PyString_Size(PyObject*);
char* PyString_AsString(PyObject*);
/* Use only if you know it's a string */
int PyString_CHECK_INTERNED()(PyObject* op) {
    return (cast(PyStringObject*)op).ob_sstate;
}
/* Macro, trading safety for speed */
PyStringObject* PyString_AS_STRING()(PyObject* op) {
    return (cast(PyStringObject*)op).ob_sval;
}
Py_ssize_t PyString_GET_SIZE()(PyObject* op) {
    return (cast(PyStringObject*)op).ob_size;
}
PyObject* PyString_Repr(PyObject*, int);
void PyString_Concat(PyObject**, PyObject*);
void PyString_ConcatAndDel(PyObject**, PyObject*);
PyObject* PyString_Format(PyObject*, PyObject*);
PyObject* PyString_DecodeEscape(const(char)*, Py_ssize_t, const(char)*, Py_ssize_t, const(char)*);

void PyString_InternInPlace(PyObject**);
void PyString_InternImmortal(PyObject**);
PyObject* PyString_InternFromString(const(char)*);

PyObject* _PyString_Join(PyObject* sep, PyObject* x);


PyObject* PyString_Decode(const(char)* s, Py_ssize_t size, const(char)* encoding, const(char) *errors);
PyObject* PyString_Encode(const(char)* s, Py_ssize_t size, const(char)* encoding, const(char)* errors);

PyObject* PyString_AsEncodedObject(PyObject* str, const(char)* encoding, const(char)* errors);
PyObject* PyString_AsDecodedObject(PyObject* str, const(char)* encoding, const(char)* errors);

// Since no one has legacy Python extensions written in D, the deprecated
// functions PyString_AsDecodedString and PyString_AsEncodedString were
// omitted.

int PyString_AsStringAndSize(PyObject* obj, char** s, int* len);

version(Python_2_6_Or_Later){
    /* Using the current locale, insert the thousands grouping
       into the string pointed to by buffer.  For the argument descriptions,
       see Objects/stringlib/localeutil.h */

    int _PyString_InsertThousandsGrouping(char* buffer,
            Py_ssize_t n_buffer,
            Py_ssize_t n_digits,
            Py_ssize_t buf_size,
            Py_ssize_t* count,
            int append_zero_char);

    /* Format the object based on the format_spec, as defined in PEP 3101
       (Advanced String Formatting). */
    PyObject*  _PyBytes_FormatAdvanced(PyObject* obj,
            char* format_spec,
            Py_ssize_t format_spec_len);
}

