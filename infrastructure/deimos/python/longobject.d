/**
  Mirror _longobject.h

  Long (arbitrary precision) integer object interface
  */
module deimos.python.longobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.unicodeobject;
import deimos.python.longintrepr;

extern(C):
// Python-header-file: Include/longobject.h:

/// _
mixin(PyAPI_DATA!"PyTypeObject PyLong_Type");

// D translation of C macro:
/// _
int PyLong_Check()(PyObject* op) {
    version(Python_2_6_Or_Later){
        return PyType_FastSubclass((op).ob_type, Py_TPFLAGS_LONG_SUBCLASS);
    }else{
        return PyObject_TypeCheck(op, &PyLong_Type);
    }
}
// D translation of C macro:
/// _
int PyLong_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyLong_Type;
}

/// _
PyObject* PyLong_FromLong(C_long);
/// _
PyObject* PyLong_FromUnsignedLong(C_ulong);

/// _
PyObject* PyLong_FromLongLong(C_longlong);
/// _
PyObject* PyLong_FromUnsignedLongLong(C_ulonglong);

/// _
PyObject* PyLong_FromDouble(double);
version(Python_2_6_Or_Later){
    /// Availability: >= 2.6
    PyObject* PyLong_FromSize_t(size_t);
    /// Availability: >= 2.6
    PyObject* PyLong_FromSsize_t(Py_ssize_t);
}
/// _
PyObject* PyLong_FromVoidPtr(void*);

/// _
C_long PyLong_AsLong(PyObject*);
/// _
C_ulong PyLong_AsUnsignedLong(PyObject*);
/// _
C_ulong PyLong_AsUnsignedLongMask(PyObject*);
version(Python_2_6_Or_Later){
    /// Availability: >= 2.6
    Py_ssize_t PyLong_AsSsize_t(PyObject*);
}
version(Python_2_7_Or_Later) {
    /// Availability: >= 2.7
    PyObject* PyLong_GetInfo();

    /** _PyLong_Frexp returns a double x and an exponent e such that the
      true value is approximately equal to x * 2**e.  e is >= 0.  x is
      0.0 if and only if the input is 0 (in which case, e and x are both
      zeroes); otherwise, 0.5 <= abs(x) < 1.0.  On overflow, which is
      possible if the number of bits doesn't fit into a Py_ssize_t, sets
      OverflowError and returns -1.0 for x, 0 for e. */
    /// Availability: >= 2.7
    double _PyLong_Frexp(PyLongObject* a, Py_ssize_t* e);
}
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    size_t PyLong_AsSize_t(PyObject*);
}

/// _
C_longlong PyLong_AsLongLong(PyObject*);
/// _
C_ulonglong PyLong_AsUnsignedLongLong(PyObject*);
/// _
C_ulonglong PyLong_AsUnsignedLongLongMask(PyObject*);
version(Python_2_7_Or_Later) {
    /// Availability: >= 2.7
    C_long PyLong_AsLongAndOverflow(PyObject*, int*);
    /// Availability: >= 2.7
    C_longlong PyLong_AsLongLongAndOverflow(PyObject*, int*);
}

/// _
double PyLong_AsDouble(PyObject*);
/// _
PyObject*  PyLong_FromVoidPtr(void*);
/// _
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
/// _
PyObject* PyLong_FromUnicode(Py_UNICODE*, int, int);
/** Return 0 if v is 0, -1 if v < 0, +1 if v > 0.
   v must not be NULL, and must be a normalized long.
   There are no error cases.
*/
int _PyLong_Sign(PyObject* v);
/** Return the number of bits needed to represent the
   absolute value of a long.  For example, this returns 1 for 1 and -1, 2
   for 2 and -2, and 2 for 3 and -3.  It returns 0 for 0.
   v must not be NULL, and must be a normalized long.
   (size_t)-1 is returned and OverflowError set if the true result doesn't
   fit in a size_t.
*/
size_t _PyLong_NumBits(PyObject* v);
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    PyObject* _PyLong_DivmodNear(PyObject*, PyObject*);
}
/** View the n unsigned bytes as a binary integer in
   base 256, and return a Python long with the same numeric value.
   If n is 0, the integer is 0.  Else:
   If little_endian is 1/true, bytes[n-1] is the MSB and bytes[0] the LSB;
   else (little_endian is 0/false) bytes[0] is the MSB and bytes[n-1] the
   LSB.
   If is_signed is 0/false, view the bytes as a non-negative integer.
   If is_signed is 1/true, view the bytes as a 2's-complement integer,
   non-negative if bit 0x80 of the MSB is clear, negative if set.
   Error returns:
   + Return NULL with the appropriate exception set if there's not
     enough memory to create the Python long.
*/
PyObject* _PyLong_FromByteArray(
        const(ubyte)* bytes, size_t n,
        int little_endian, int is_signed);
/** Convert the least-significant 8*n bits of long
   v to a base-256 integer, stored in array bytes.  Normally return 0,
   return -1 on error.
   If little_endian is 1/true, store the MSB at bytes[n-1] and the LSB at
   bytes[0]; else (little_endian is 0/false) store the MSB at bytes[0] and
   the LSB at bytes[n-1].
   If is_signed is 0/false, it's an error if v < 0; else (v >= 0) n bytes
   are filled and there's nothing special about bit 0x80 of the MSB.
   If is_signed is 1/true, bytes is filled with the 2's-complement
   representation of v's value.  Bit 0x80 of the MSB is the sign bit.
   Error returns (-1):
   + is_signed is 0 and v < 0.  TypeError is set in this case, and bytes
     isn't altered.
   + n isn't big enough to hold the full mathematical value of v.  For
     example, if is_signed is 0 and there are more digits in the v than
     fit in n; or if is_signed is 1, v < 0, and n is just 1 bit shy of
     being large enough to hold a sign bit.  OverflowError is set in this
     case, but bytes holds the least-signficant n bytes of the true value.
*/
int _PyLong_AsByteArray(PyLongObject* v,
        ubyte* bytes, size_t n,
        int little_endian, int is_signed);

version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    PyObject* _PyLong_Format(PyObject* aa, int base);
    /// Availability: 3.*
    PyObject* _PyLong_FormatAdvanced(PyObject* obj,
            Py_UNICODE* format_spec,
            Py_ssize_t format_spec_len);
    /// Availability: 3.*
    C_ulong PyOS_strtoul(char*, char**, int);
    /// Availability: 3.*
    C_long PyOS_strtol(char*, char**, int);
}else version(Python_2_6_Or_Later) {
    /** _PyLong_Format: Convert the long to a string object with given base,
       appending a base prefix of 0[box] if base is 2, 8 or 16.
       Add a trailing "L" if addL is non-zero.
       If newstyle is zero, then use the pre-2.6 behavior of octal having
       a leading "0", instead of the prefix "0o" */
    PyObject* _PyLong_Format(PyObject* aa, int base, int addL, int newstyle);
    /** Format the object based on the format_spec, as defined in PEP 3101
       (Advanced String Formatting). */
    PyObject* _PyLong_FormatAdvanced(PyObject* obj,
            char *format_spec,
            Py_ssize_t format_spec_len);
}



