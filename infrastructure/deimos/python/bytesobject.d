/**
  Mirror _bytesobject.h

  Note _bytesobject.h did not exist before python 2.6; however
  for python 2, it simply provides aliases to contents of stringobject.h,
  so we provide them anyways to make it easier to write portable extension
  modules.
  */
module deimos.python.bytesobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.stringobject;
import core.stdc.stdarg;

version(Python_3_0_Or_Later) {
        /**
         * subclass of PyVarObject.
         *
         * Invariants:
         *     ob_sval contains space for 'ob_size+1' elements.
         *     ob_sval[ob_size] == 0.
         *     ob_shash is the hash of the string or -1 if not computed yet.
         *
         */
    extern(C):
    struct PyBytesObject{
        mixin PyObject_VAR_HEAD;
        /// _
        Py_hash_t ob_shash;
        char[1] _ob_sval;
        /// _
        @property char* ob_sval()() {
            return _ob_sval.ptr;
        }

    }

    ///
    mixin(PyAPI_DATA!"PyTypeObject PyBytes_Type");
    ///
    mixin(PyAPI_DATA!"PyTypeObject PyBytesIter_Type");
    // D translation of C macro:
    ///
    int PyBytes_Check()(PyObject* op) {
        return PyType_FastSubclass(Py_TYPE(op), Py_TPFLAGS_BYTES_SUBCLASS);
    }
    ///
    int PyBytes_CheckExact()(PyObject* op) {
        return Py_TYPE(op) is &PyBytes_Type;
    }

    ///
    PyObject* PyBytes_FromStringAndSize(const(char)*, Py_ssize_t);
    ///
    PyObject* PyBytes_FromString(const(char)*);
    ///
    PyObject* PyBytes_FromObject(PyObject*);
    ///
    PyObject* PyBytes_FromFormatV(const(char)*, va_list);
    ///
    PyObject* PyBytes_FromFormat(const(char)*, ...);
    ///
    Py_ssize_t PyBytes_Size(PyObject*);
    ///
    const(char)* PyBytes_AsString(PyObject*);
    ///
    PyObject* PyBytes_Repr(PyObject*, int);
    ///
    void PyBytes_Concat(PyObject**, PyObject*);
    ///
    void PyBytes_ConcatAndDel(PyObject**, PyObject*);
    ///
    int _PyBytes_Resize(PyObject**, Py_ssize_t);
    ///
    PyObject* _PyBytes_FormatLong(PyObject*, int, int,
            int, char**, int*);
    ///
    PyObject* PyBytes_DecodeEscape(const(char)*, Py_ssize_t,
            const(char)*, Py_ssize_t,
            const(char)*);
    // D translation of C macro:
    ///
    const(char)* PyBytes_AS_STRING()(PyObject* op) {
        assert(PyBytes_Check(op));
        return (cast(PyBytesObject*) op).ob_sval;


    }
    ///
    auto PyBytes_GET_SIZE()(PyObject* op) {
        assert(PyBytes_Check(op));
        return Py_SIZE(op);
    }
    ///
    PyObject* _PyBytes_Join(PyObject* sep, PyObject* x);
    /**
Params:
obj = string or Unicode object
s = pointer to buffer variable
len = pointer to length variable or NULL (only possible for 0-terminated
                                   strings)
     */
    int PyBytes_AsStringAndSize(
            PyObject* obj,
            char** s,
            Py_ssize_t* len
            );
    ///
    Py_ssize_t _PyBytes_InsertThousandsGroupingLocale(
            char* buffer,
            Py_ssize_t n_buffer,
            char* digits,
            Py_ssize_t n_digits,
            Py_ssize_t min_width);

    /** Using explicit passed-in values, insert the thousands grouping
       into the string pointed to by buffer.  For the argument descriptions,
       see Objects/stringlib/localeutil.h */
    Py_ssize_t _PyBytes_InsertThousandsGrouping(
            char* buffer,
            Py_ssize_t n_buffer,
            char* digits,
            Py_ssize_t n_digits,
            Py_ssize_t min_width,
            const(char)* grouping,
            const char* thousands_sep);

    ///
enum F_LJUST =      (1<<0);
    ///
enum F_SIGN =       (1<<1);
    ///
enum F_BLANK =      (1<<2);
    ///
enum F_ALT =        (1<<3);
    ///
enum F_ZERO =       (1<<4);

}else {
    ///
    alias PyStringObject PyBytesObject;
    ///
    alias PyString_Type PyBytes_Type;
    ///
    alias PyString_Check PyBytes_Check;
    ///
    alias PyString_CheckExact PyBytes_CheckExact;
    ///
    alias PyString_CHECK_INTERNED PyBytes_CHECK_INTERNED;
    ///
    alias PyString_AS_STRING PyBytes_AS_STRING;
    ///
    alias PyString_GET_SIZE PyBytes_GET_SIZE;
    version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    alias Py_TPFLAGS_STRING_SUBCLASS Py_TPFLAGS_BYTES_SUBCLASS;
    }
    ///
    alias PyString_FromStringAndSize PyBytes_FromStringAndSize;
    ///
    alias PyString_FromString PyBytes_FromString;
    ///
    alias PyString_FromFormatV PyBytes_FromFormatV;
    ///
    alias PyString_FromFormat PyBytes_FromFormat;
    ///
    alias PyString_Size PyBytes_Size;
    ///
    alias PyString_AsString PyBytes_AsString;
    ///
    alias PyString_Repr PyBytes_Repr;
    ///
    alias PyString_Concat PyBytes_Concat;
    ///
    alias PyString_ConcatAndDel PyBytes_ConcatAndDel;
    ///
    alias _PyString_Resize _PyBytes_Resize;
    ///
    alias _PyString_Eq _PyBytes_Eq;
    ///
    alias PyString_Format PyBytes_Format;
    ///
    alias _PyString_FormatLong _PyBytes_FormatLong;
    ///
    alias PyString_DecodeEscape PyBytes_DecodeEscape;
    ///
    alias _PyString_Join _PyBytes_Join;
    version(Python_2_7_Or_Later) {
        // went away in python 2.7
    }else {
        /// Availability: <= 2.6
        alias PyString_Decode PyBytes_Decode;
        /// Availability: <= 2.6
        alias PyString_Encode PyBytes_Encode;
        /// Availability: <= 2.6
        alias PyString_AsEncodedObject PyBytes_AsEncodedObject;
        /// Availability: <= 2.6
        alias PyString_AsDecodedObject PyBytes_AsDecodedObject;
        /*
        alias PyString_AsEncodedString PyBytes_AsEncodedString;
        alias PyString_AsDecodedString PyBytes_AsDecodedString;
        */
    }
    ///
    alias PyString_AsStringAndSize PyBytes_AsStringAndSize;
    version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    alias _PyString_InsertThousandsGrouping _PyBytes_InsertThousandsGrouping;
    }
}
