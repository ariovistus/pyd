/**
  Mirrors _stringobject.h

Type PyStringObject represents a character string.  An extra zero byte is
reserved at the end to ensure it is zero-terminated, but a size is
present so strings with null bytes in them can be represented.  This
is an immutable object type.

There are functions to create new string objects, to test
an object for string-ness, and to get the
string value.  The latter function returns a null pointer
if the object is not of the proper type.
There is a variant that takes an explicit size as well as a
variant that assumes a zero-terminated string.  Note that none of the
functions should be applied to nil objects.

Note _stringobject goes away in python 3 (well, sort of; it gets moved to
bytesobject.h - look there for portability)
  */
module deimos.python.stringobject;

import deimos.python.pyport;
import deimos.python.object;
import core.stdc.stdarg;

version(Python_3_0_Or_Later) {
}else{
extern(C):
// Python-header-file: Include/stringobject.h:

/** Invariants:
 *     ob_sval contains space for 'ob_size+1' elements.
 *     ob_sval[ob_size] == 0.
 *     ob_shash is the hash of the string or -1 if not computed yet.
 *     ob_sstate != 0 iff the string object is in stringobject.c's
 *       'interned' dictionary; in this case the two references
 *       from 'interned' to this object are *not counted* in ob_refcnt.
 *
 * subclass of PyVarObject
 */
/// Availability: 2.*
struct PyStringObject {
    mixin PyObject_VAR_HEAD;

    ///_
    C_long ob_shash;
    ///_
    int ob_sstate;
    // Will the D layout for a 1-char array be the same as the C layout?  I
    // think the D array will be larger.
    // John-Colvin 2014-10-14: It should be the same. char[1].sizeof == 1
    char[1] _ob_sval;
    ///_
    char* ob_sval()() {
        return _ob_sval.ptr;
    }
}

/// Availability: 2.*
mixin(PyAPI_DATA!"PyTypeObject PyBaseString_Type");
/// Availability: 2.*
mixin(PyAPI_DATA!"PyTypeObject PyString_Type");

// D translation of C macro:
/// Availability: 2.*
int PyString_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, &PyString_Type);
}
// D translation of C macro:
/// Availability: 2.*
int PyString_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyString_Type;
}

/**
   For PyString_FromString(), the parameter `str' points to a null-terminated
   string containing exactly `size' bytes.

   For PyString_FromStringAndSize(), the parameter the parameter `str' is
   either NULL or else points to a string containing at least `size' bytes.
   For PyString_FromStringAndSize(), the string in the `str' parameter does
   not have to be null-terminated.  (Therefore it is safe to construct a
   substring by calling `PyString_FromStringAndSize(origstring, substrlen)'.)
   If `str' is NULL then PyString_FromStringAndSize() will allocate `size+1'
   bytes (setting the last byte to the null terminating character) and you can
   fill in the data yourself.  If `str' is non-NULL then the resulting
   PyString object must be treated as immutable and you must not fill in nor
   alter the data yourself, since the strings may be shared.

   The PyObject member `op->ob_size', which denotes the number of "extra
   items" in a variable-size object, will contain the number of bytes
   allocated for string data, not counting the null terminating character.
   It is therefore equal to the `size' parameter (for
   PyString_FromStringAndSize()) or the length of the string in the `str'
   parameter (for PyString_FromString()).
*/
/// Availability: 2.*
PyObject* PyString_FromStringAndSize(const(char)*, Py_ssize_t);
/// ditto
PyObject* PyString_FromString(const(char)*);
/// Availability: 2.*
PyObject* PyString_FromFormatV(const(char)*,  va_list);
/// Availability: 2.*
PyObject* PyString_FromFormat(const(char)*, ...);
/// Availability: 2.*
Py_ssize_t PyString_Size(PyObject*);
/// Availability: 2.*
const(char)* PyString_AsString(PyObject*);
/** Use only if you know it's a string */
/// Availability: 2.*
int PyString_CHECK_INTERNED()(PyObject* op) {
    return (cast(PyStringObject*)op).ob_sstate;
}
/** Macro, trading safety for speed */
/// Availability: 2.*
const(char)* PyString_AS_STRING()(PyObject* op) {
    return (cast(PyStringObject*)op).ob_sval;
}
/// Availability: 2.*
Py_ssize_t PyString_GET_SIZE()(PyObject* op) {
    return (cast(PyStringObject*)op).ob_size;
}
/// Availability: 2.*
PyObject* PyString_Repr(PyObject*, int);
/// Availability: 2.*
void PyString_Concat(PyObject**, PyObject*);
/// Availability: 2.*
void PyString_ConcatAndDel(PyObject**, PyObject*);
/// Availability: 2.*
int _PyString_Resize(PyObject**, Py_ssize_t);
/// Availability: 2.*
int _PyString_Eq(PyObject*, PyObject*);
/// Availability: 2.*
PyObject* PyString_Format(PyObject*, PyObject*);
/// Availability: 2.*
PyObject* _PyString_FormatLong(PyObject*, int, int, int, char**, int*);
/// Availability: 2.*
PyObject* PyString_DecodeEscape(const(char)*, Py_ssize_t, const(char)*, Py_ssize_t, const(char)*);

/// Availability: 2.*
void PyString_InternInPlace(PyObject**);
/// Availability: 2.*
void PyString_InternImmortal(PyObject**);
/// Availability: 2.*
PyObject* PyString_InternFromString(const(char)*);

/// Availability: 2.*
PyObject* _PyString_Join(PyObject* sep, PyObject* x);

/// Availability: 2.*
PyObject* PyString_Decode(const(char)* s, Py_ssize_t size, const(char)* encoding, const(char) *errors);
/// Availability: 2.*
PyObject* PyString_Encode(const(char)* s, Py_ssize_t size, const(char)* encoding, const(char)* errors);

/// Availability: 2.*
PyObject* PyString_AsEncodedObject(PyObject* str, const(char)* encoding, const(char)* errors);
/// Availability: 2.*
PyObject* PyString_AsDecodedObject(PyObject* str, const(char)* encoding, const(char)* errors);

// Since no one has legacy Python extensions written in D, the deprecated
// functions PyString_AsDecodedString and PyString_AsEncodedString were
// omitted.

/// Availability: 2.*
int PyString_AsStringAndSize(PyObject* obj, char** s, int* len);

version(Python_2_6_Or_Later){
    /** Using the current locale, insert the thousands grouping
       into the string pointed to by buffer.  For the argument descriptions,
       see Objects/stringlib/localeutil.h */

    /// Availability: 2.6, 2.7
    int _PyString_InsertThousandsGrouping(char* buffer,
            Py_ssize_t n_buffer,
            Py_ssize_t n_digits,
            Py_ssize_t buf_size,
            Py_ssize_t* count,
            int append_zero_char);

    /** Format the object based on the format_spec, as defined in PEP 3101
       (Advanced String Formatting). */
    /// Availability: 2.6, 2.7
    PyObject*  _PyBytes_FormatAdvanced(PyObject* obj,
            char* format_spec,
            Py_ssize_t format_spec_len);
}

}
