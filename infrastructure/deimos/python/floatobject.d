/**
  Mirror _floatobject.h
  */
module deimos.python.floatobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.unicodeobject;
import deimos.python.pythonrun;
import core.stdc.stdio;

extern(C):
// Python-header-file: Include/floatobject.h:

/// subclass of PyObject
struct PyFloatObject {
    mixin PyObject_HEAD;
    /// _
    double ob_fval;
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PyFloat_Type");

// D translation of C macro:
/// _
int PyFloat_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, &PyFloat_Type);
}
// D translation of C macro:
/// _
int PyFloat_CheckExact()(PyObject *op) {
    return Py_TYPE(op) == &PyFloat_Type;
}

version(Python_2_6_Or_Later){
    /// Availability: >= 2.6
    double PyFloat_GetMax();
    /// Availability: >= 2.6
    double PyFloat_GetMin();
    /// Availability: >= 2.6
    PyObject* PyFloat_GetInfo();
}

version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    PyObject* PyFloat_FromString(PyObject*);
}else{
    /** Return Python float from string PyObject.  Second argument ignored on
      input, and, if non-NULL, NULL is stored into *junk (this tried to serve a
      purpose once but can't be made to work as intended). */
    /// Availability: 2.*
    PyObject* PyFloat_FromString(PyObject*, char** junk);
}
/** Return Python float from C double. */
PyObject* PyFloat_FromDouble(double);

/** Extract C double from Python float.  The macro version trades safety for
   speed. */
double PyFloat_AsDouble(PyObject*);
/// ditto
double PyFloat_AS_DOUBLE()(PyObject* op) {
    return (cast(PyFloatObject*)op).ob_fval;
}
version(Python_3_0_Or_Later) {
}else{
    /** Write repr(v) into the char buffer argument, followed by null byte.  The
      buffer must be "big enough"; >= 100 is very safe.
      PyFloat_AsReprString(buf, x) strives to print enough digits so that
      PyFloat_FromString(buf) then reproduces x exactly. */
    /// Availability: 2.*
    void PyFloat_AsReprString(char*, PyFloatObject* v);
    /** Write str(v) into the char buffer argument, followed by null byte.  The
       buffer must be "big enough"; >= 100 is very safe.  Note that it's
       unusual to be able to get back the float you started with from
       PyFloat_AsString's result -- use PyFloat_AsReprString() if you want to
       preserve precision across conversions. */
    /// Availability: 2.*
    void PyFloat_AsString(char*, PyFloatObject* v);
}

/** _PyFloat_{Pack,Unpack}{4,8}
 *
 * The struct and pickle (at least) modules need an efficient platform-
 * independent way to store floating-point values as byte strings.
 * The Pack routines produce a string from a C double, and the Unpack
 * routines produce a C double from such a string.  The suffix (4 or 8)
 * specifies the number of bytes in the string.
 *
 * On platforms that appear to use (see _PyFloat_Init()) IEEE-754 formats
 * these functions work by copying bits.  On other platforms, the formats the
 * 4- byte format is identical to the IEEE-754 single precision format, and
 * the 8-byte format to the IEEE-754 double precision format, although the
 * packing of INFs and NaNs (if such things exist on the platform) isn't
 * handled correctly, and attempting to unpack a string containing an IEEE
 * INF or NaN will raise an exception.
 *
 * On non-IEEE platforms with more precision, or larger dynamic range, than
 * 754 supports, not all values can be packed; on non-IEEE platforms with less
 * precision, or smaller dynamic range, not all values can be unpacked.  What
 * happens in such cases is partly accidental (alas).
 *
 * The pack routines write 4 or 8 bytes, starting at p.  le is a bool
 * argument, true if you want the string in little-endian format (exponent
 * last, at p+3 or p+7), false if you want big-endian format (exponent
 * first, at p).
 * Return value:  0 if all is OK, -1 if error (and an exception is
 * set, most likely OverflowError).
 * There are two problems on non-IEEE platforms:
 * 1):  What this does is undefined if x is a NaN or infinity.
 * 2):  -0.0 and +0.0 produce the same string.
 */
int _PyFloat_Pack4(double x, ubyte* p, int le);
/// ditto
int _PyFloat_Pack8(double x, ubyte* p, int le);

version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    int _PyFloat_Repr(double x, char* p, size_t len);
}

version(Python_2_6_Or_Later){
    /** Used to get the important decimal digits of a double */
    /// Availability: >= 2.6
    int _PyFloat_Digits(char* buf, double v, int* signum);
    /// Availability: >= 2.6
    void _PyFloat_DigitsInit();
    /** The unpack routines read 4 or 8 bytes, starting at p.  le is a bool
     * argument, true if the string is in little-endian format (exponent
     * last, at p+3 or p+7), false if big-endian (exponent first, at p).
     * Return value:  The unpacked double.  On error, this is -1.0 and
     * PyErr_Occurred() is true (and an exception is set, most likely
     * OverflowError).  Note that on a non-IEEE platform this will refuse
     * to unpack a string that represents a NaN or infinity.
     */
    double _PyFloat_Unpack4(const(ubyte)* p, int le);
    /// ditto
    double _PyFloat_Unpack8(const(ubyte)* p, int le);
    /** free list api */
    /// Availability: >= 2.6
    int PyFloat_ClearFreeList();
}

version(Python_2_7_Or_Later) {
    /// Availability: >= 2.7
    void _PyFloat_DebugMallocStats(FILE* out_);
}
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    PyObject* _PyFloat_FormatAdvanced(PyObject* obj,
            Py_UNICODE* format_spec,
            Py_ssize_t format_spec_len);
}else{
    version(Python_2_7_Or_Later) {
        /** Round a C double x to the closest multiple of 10**-ndigits.
          Returns a Python float on success, or NULL (with an appropriate
          exception set) on failure.  Used in builtin_round in bltinmodule.c.
         */
        /// Availability: >= 2.7
        PyObject* _Py_double_round(double x, int ndigits);
    }
    version(Python_2_6_Or_Later) {
        /** Format the object based on the format_spec, as defined in PEP 3101
           (Advanced String Formatting). */
        /// Availability: >= 2.6
        PyObject* _PyFloat_FormatAdvanced(PyObject* obj,
                char* format_spec,
                Py_ssize_t format_spec_len);
    }
}
