/**
  Mirror _unicodeobject.h

  Unicode API names are mangled to assure that UCS-2 and UCS-4 builds
  produce different external names and thus cause import errors in
  case Python interpreters and extensions with mixed compiled in
  Unicode width assumptions are combined.
  */
module deimos.python.unicodeobject;

import core.stdc.stdarg;
import core.stdc.string;
import core.stdc.stddef : wchar_t;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/unicodeobject.h:

/** Py_UNICODE is the native Unicode storage format (code unit) used by
   Python and represents a single Unicode element in the Unicode
   type. */
version (Python_Unicode_UCS2) {
    version (Windows) {
        alias wchar_t Py_UNICODE;
    } else {
        alias ushort Py_UNICODE;
    }
} else {
    alias uint Py_UNICODE;
}
alias Py_UNICODE Py_UCS4;
alias ubyte Py_UCS1;
alias ushort Py_UCS2;

version(Python_3_4_Or_Later) {
    /** There are 4 forms of Unicode strings:
       - compact ascii:
         * structure = PyASCIIObject
         * test: PyUnicode_IS_COMPACT_ASCII(op)
         * kind = PyUnicode_1BYTE_KIND
         * compact = 1
         * ascii = 1
         * ready = 1
         * (length is the length of the utf8 and wstr strings)
         * (data starts just after the structure)
         * (since ASCII is decoded from UTF-8, the utf8 string are the data)
       - compact:
         * structure = PyCompactUnicodeObject
         * test: PyUnicode_IS_COMPACT(op) && !PyUnicode_IS_ASCII(op)
         * kind = PyUnicode_1BYTE_KIND, PyUnicode_2BYTE_KIND or
           PyUnicode_4BYTE_KIND
         * compact = 1
         * ready = 1
         * ascii = 0
         * utf8 is not shared with data
         * utf8_length = 0 if utf8 is NULL
         * wstr is shared with data and wstr_length=length
           if kind=PyUnicode_2BYTE_KIND and sizeof(wchar_t)=2
           or if kind=PyUnicode_4BYTE_KIND and sizeof(wchar_t)=4
         * wstr_length = 0 if wstr is NULL
         * (data starts just after the structure)
       - legacy string, not ready:
         * structure = PyUnicodeObject
         * test: kind == PyUnicode_WCHAR_KIND
         * length = 0 (use wstr_length)
         * hash = -1
         * kind = PyUnicode_WCHAR_KIND
         * compact = 0
         * ascii = 0
         * ready = 0
         * interned = SSTATE_NOT_INTERNED
         * wstr is not NULL
         * data.any is NULL
         * utf8 is NULL
         * utf8_length = 0
       - legacy string, ready:
         * structure = PyUnicodeObject structure
         * test: !PyUnicode_IS_COMPACT(op) && kind != PyUnicode_WCHAR_KIND
         * kind = PyUnicode_1BYTE_KIND, PyUnicode_2BYTE_KIND or
           PyUnicode_4BYTE_KIND
         * compact = 0
         * ready = 1
         * data.any is not NULL
         * utf8 is shared and utf8_length = length with data.any if ascii = 1
         * utf8_length = 0 if utf8 is NULL
         * wstr is shared with data.any and wstr_length = length
           if kind=PyUnicode_2BYTE_KIND and sizeof(wchar_t)=2
           or if kind=PyUnicode_4BYTE_KIND and sizeof(wchar_4)=4
         * wstr_length = 0 if wstr is NULL
       Compact strings use only one memory block (structure + characters),
       whereas legacy strings use one block for the structure and one block
       for characters.
       Legacy strings are created by PyUnicode_FromUnicode() and
       PyUnicode_FromStringAndSize(NULL, size) functions. They become ready
       when PyUnicode_READY() is called.
       See also _PyUnicode_CheckConsistency().
	Availability >= 3.4
    */
	struct PyASCIIObject {
		mixin PyObject_HEAD;
		/** Number of code points in the string */
		Py_ssize_t length;
		/** Hash value; -1 if not set */
		Py_hash_t hash;
		/// _
		int state;
		/** wchar_t representation (null-terminated) */
		wchar_t* wstr;
	}

    /// Availability >= 3.4
    struct PyCompactUnicodeObject {
        /// _
        PyASCIIObject _base;
        /// _
        Py_ssize_t utf8_length;
        /// _
        char* utf8;
        /// _
        Py_ssize_t wstr_length;
    }

    /**
      subclass of PyObject.
      */
    struct PyUnicodeObject {
        PyCompactUnicodeObject _base;
        PyUnicodeObject_data data;
    }

    union PyUnicodeObject_data {
        void* any;
        Py_UCS1* latin1;
        Py_UCS2* ucs2;
        Py_UCS4* ucs4;
    }
}else{
    /**
      subclass of PyObject.
      */
    struct PyUnicodeObject {
        mixin PyObject_HEAD;
        /** Length of raw Unicode data in buffer */
        Py_ssize_t length;
        /** Raw Unicode buffer */
        Py_UNICODE* str;
        /** Hash value; -1 if not set */
        C_long hash;
        /** (Default) Encoded version as Python
          string, or NULL; this is used for
          implementing the buffer protocol */
        PyObject* defenc;
    }
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PyUnicode_Type");

// D translations of C macros:
/** Fast access macros */
int PyUnicode_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, &PyUnicode_Type);
}
/// ditto
int PyUnicode_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyUnicode_Type;
}

/// ditto
size_t PyUnicode_GET_SIZE()(PyUnicodeObject* op) {
    return op.length;
}
/// ditto
size_t PyUnicode_GET_DATA_SIZE()(PyUnicodeObject* op) {
    return op.length * Py_UNICODE.sizeof;
}
/// ditto
Py_UNICODE* PyUnicode_AS_UNICODE()(PyUnicodeObject* op) {
    return op.str;
}
/// ditto
const(char)* PyUnicode_AS_DATA()(PyUnicodeObject* op) {
    return cast(const(char)*) op.str;
}

/** This Unicode character will be used as replacement character during
   decoding if the errors argument is set to "replace". Note: the
   Unicode character U+FFFD is the official REPLACEMENT CHARACTER in
   Unicode 3.0. */
enum Py_UNICODE Py_UNICODE_REPLACEMENT_CHARACTER = 0xFFFD;

version(Python_3_3_Or_Later) {
    enum PyUnicode_ = "PyUnicode_";
}else version(Python_Unicode_UCS2) {
    enum PyUnicode_ = "PyUnicodeUCS2_";
}else{
    enum PyUnicode_ = "PyUnicodeUCS4_";
}

/*
   this function takes defs PyUnicode_XX and transforms them to
   PyUnicodeUCS4_XX();
   alias PyUnicodeUCS4_XX PyUnicode_XX;

   */
string substitute_and_alias()(string code) {
    import std.algorithm;
    import std.array;
    string[] newcodes;
LOOP:
    while(true) {
        if(startsWith(code,"/*")) {
            size_t comm_end_index = countUntil(code[2 .. $], "*/");
            if(comm_end_index == -1) break;
            newcodes ~= code[0 .. comm_end_index];
            code = code[comm_end_index .. $];
            continue;
        }
        if(!(startsWith(code,"PyUnicode_") || startsWith(code,"_PyUnicode"))) {
            size_t index = 0;
            while(index < code.length) {
                if(code[index] == '_') {
                    if(startsWith(code[index .. $], "_PyUnicode_")) {
                        break;
                    }
                }else if(code[index] == 'P') {
                    if(startsWith(code[index .. $], "PyUnicode_")) {
                        break;
                    }
                }else if(code[index] == '/') {
                    if(startsWith(code[index .. $], "/*")) {
                        break;
                    }
                }
                index++;
            }
            if(index == code.length) break;
            newcodes ~= code[0 .. index];
            code = code[index .. $];
            continue;
        }
        size_t end_index = countUntil(code, "(");
        if(end_index == -1) break;
        string alias_name = code[0 .. end_index];
        string func_name = replace(alias_name, "PyUnicode_", PyUnicode_);
        size_t index0 = end_index+1;
        int parencount = 1;
        while(parencount && index0 < code.length) {
            if(startsWith(code[index0 .. $], "/*")) {
                size_t comm_end_index = countUntil(code[index0+2 .. $], "*/");
                if(comm_end_index == -1) break LOOP;
                index0 += comm_end_index;
                continue;
            }else if(code[index0] == '(') {
                parencount++;
                index0++;
            }else if(code[index0] == ')') {
                parencount--;
                index0++;
            }else{
                index0++;
            }
        }
        size_t semi = countUntil(code[index0 .. $], ";");
        if(semi == -1) break;
        index0 += semi+1;

        string alias_line = "\nalias " ~ func_name ~ " " ~ alias_name ~ ";\n";
        newcodes ~= func_name;
        newcodes ~= code[end_index .. index0];
        newcodes ~= "\n /// ditto \n";
        newcodes ~= alias_line;

        code = code[index0 .. $];
    }

    string newcode;
    foreach(c; newcodes) {
        newcode ~= c;
    }
    return newcode;
}

enum string unicode_funs = q{
    version(Python_2_6_Or_Later) {

    /** Create a Unicode Object from the Py_UNICODE buffer u of the given
       size.

       u may be NULL which causes the contents to be undefined. It is the
       user's responsibility to fill in the needed data afterwards. Note
       that modifying the Unicode object contents after construction is
       only allowed if u was set to NULL.

       The buffer is copied into the new object. */
        /// Availability: >= 2.6
        PyObject* PyUnicode_FromUnicode(Py_UNICODE* u, Py_ssize_t size);

      /** Similar to PyUnicode_FromUnicode(), but u points to Latin-1 encoded bytes */
        /// Availability: >= 2.6
      PyObject* PyUnicode_FromStringAndSize(
              const(char)*u,        /* char buffer */
              Py_ssize_t size       /* size of buffer */
              );

      /** Similar to PyUnicode_FromUnicode(), but u points to null-terminated
         Latin-1 encoded bytes */
        /// Availability: >= 2.6
      PyObject* PyUnicode_FromString(
              const(char)*u        /* string */
              );
        /// Availability: >= 2.6
      PyObject* PyUnicode_FromFormatV(const(char)*, va_list);
        /// Availability: >= 2.6
      PyObject* PyUnicode_FromFormat(const(char)*, ...);

      /** Format the object based on the format_spec, as defined in PEP 3101
         (Advanced String Formatting). */
        /// Availability: >= 2.6
      PyObject* _PyUnicode_FormatAdvanced(PyObject *obj,
              Py_UNICODE *format_spec,
              Py_ssize_t format_spec_len);
        /// Availability: >= 2.6
      int PyUnicode_ClearFreeList();
      /**
Params:
string = UTF-7 encoded string
length = size of string
error = error handling
consumed = bytes consumed
*/
        /// Availability: >= 2.6
      PyObject* PyUnicode_DecodeUTF7Stateful(
              const(char)* string,
              Py_ssize_t length,
              const(char)*errors,
              Py_ssize_t *consumed
              );
      /**
Params:
string = UTF-32 encoded string
length = size of string
error = error handling
byteorder = pointer to byteorder to use 0=native;-1=LE,1=BE; updated on exit
*/
        /// Availability: >= 2.6
      PyObject* PyUnicode_DecodeUTF32(
              const(char)* string,
              Py_ssize_t length,
              const(char)*errors,
              int *byteorder
              );

      /**
Params:
string = UTF-32 encoded string
length = size of string
error = error handling
byteorder = pointer to byteorder to use 0=native;-1=LE,1=BE; updated on exit
*/
        /// Availability: >= 2.6
      PyObject* PyUnicode_DecodeUTF32Stateful(
              const(char)*string,
              Py_ssize_t length,
              const(char)*errors,
              int *byteorder,
              Py_ssize_t *consumed
              );
      /** Returns a Python string using the UTF-32 encoding in native byte
         order. The string always starts with a BOM mark.  */
        /// Availability: >= 2.6

      PyObject* PyUnicode_AsUTF32String(
              PyObject *unicode
              );

      /** Returns a Python string object holding the UTF-32 encoded value of
         the Unicode data.

         If byteorder is not 0, output is written according to the following
         byte order:

         byteorder == -1: little endian
         byteorder == 0:  native byte order (writes a BOM mark)
         byteorder == 1:  big endian

         If byteorder is 0, the output string will always start with the
         Unicode BOM mark (U+FEFF). In the other two modes, no BOM mark is
         prepended.
Params:
data = Unicode char buffer
length = number of Py_UNICODE chars to encode
errors = error handling
byteorder = byteorder to use 0=BOM+native;-1=LE,1=BE

       */
        /// Availability: >= 2.6
      PyObject* PyUnicode_EncodeUTF32(
              const Py_UNICODE *data,
              Py_ssize_t length,
              const(char)* errors,
              int byteorder
              );
      }

    /** Return a read-only pointer to the Unicode object's internal
      Py_UNICODE buffer. */
    Py_UNICODE* PyUnicode_AsUnicode(PyObject* unicode);
    /** Get the length of the Unicode object. */
    Py_ssize_t PyUnicode_GetSize(PyObject* unicode);

    /** Get the maximum ordinal for a Unicode character. */
    Py_UNICODE PyUnicode_GetMax();

    /** Resize an already allocated Unicode object to the new size length.

   _*unicode is modified to point to the new (resized) object and 0
   returned on success.

   This API may only be called by the function which also called the
   Unicode constructor. The refcount on the object must be 1. Otherwise,
   an error is returned.

   Error handling is implemented as follows: an exception is set, -1
   is returned and *unicode left untouched.
Params:
unicode = pointer to the new unicode object.
length = New length.

*/
    int PyUnicode_Resize(PyObject** unicode, Py_ssize_t length);
    /** Coerce obj to an Unicode object and return a reference with
     _*incremented* refcount.

     Coercion is done in the following way:

     1. String and other char buffer compatible objects are decoded
     under the assumptions that they contain data using the current
     default encoding. Decoding is done in "strict" mode.

     2. All other objects (including Unicode objects) raise an
     exception.

     The API returns NULL in case of an error. The caller is responsible
     for decref'ing the returned objects.

     */
    PyObject* PyUnicode_FromEncodedObject(
            PyObject* obj,
            const(char)* encoding,
            const(char)* errors);

    /** Coerce obj to an Unicode object and return a reference with
     _*incremented* refcount.

     Unicode objects are passed back as-is (subclasses are converted to
     true Unicode objects), all other objects are delegated to
     PyUnicode_FromEncodedObject(obj, NULL, "strict") which results in
     using the default encoding as basis for decoding the object.

     The API returns NULL in case of an error. The caller is responsible
     for decref'ing the returned objects.

     */
    PyObject* PyUnicode_FromObject(PyObject* obj);

    /** Create a Unicode Object from the whcar_t buffer w of the given
      size.

      The buffer is copied into the new object. */
    PyObject* PyUnicode_FromWideChar(const(wchar_t)* w, Py_ssize_t size);

    /** Copies the Unicode Object contents into the wchar_t buffer w.  At
      most size wchar_t characters are copied.

      Note that the resulting wchar_t string may or may not be
      0-terminated.  It is the responsibility of the caller to make sure
      that the wchar_t string is 0-terminated in case this is required by
      the application.

      Returns the number of wchar_t characters copied (excluding a
      possibly trailing 0-termination character) or -1 in case of an
      error. */
    Py_ssize_t PyUnicode_AsWideChar(
            PyUnicodeObject* unicode,
            const(wchar_t)* w,
            Py_ssize_t size);

    /** Create a Unicode Object from the given Unicode code point ordinal.

       The ordinal must be in range(0x10000) on narrow Python builds
       (UCS2), and range(0x110000) on wide builds (UCS4). A ValueError is
       raised in case it is not.

     */
    PyObject* PyUnicode_FromOrdinal(int ordinal);

    /** Return a Python string holding the default encoded value of the
      Unicode object.

      The resulting string is cached in the Unicode object for subsequent
      usage by this function. The cached version is needed to implement
      the character buffer interface and will live (at least) as long as
      the Unicode object itself.

      The refcount of the string is *not* incremented.

     _*** Exported for internal use by the interpreter only !!! ***

     */
    PyObject* _PyUnicode_AsDefaultEncodedString(PyObject *, const(char)*);

    /** Returns the currently active default encoding.

      The default encoding is currently implemented as run-time settable
      process global.  This may change in future versions of the
      interpreter to become a parameter which is managed on a per-thread
      basis.

     */
    const(char)* PyUnicode_GetDefaultEncoding();

    /** Sets the currently active default encoding.

       Returns 0 on success, -1 in case of an error.

     */
    int PyUnicode_SetDefaultEncoding(const(char)*encoding);

    /** Create a Unicode object by decoding the encoded string s of the
      given size.
Params:
s = encoded string
size = size of buffer
encoding = encoding
errors = error handling
     */
    PyObject* PyUnicode_Decode(
            const(char)* s,
            Py_ssize_t size,
            const(char)* encoding,
            const(char)* errors);

    version(Python_3_6_Or_Later) {
        /** Decode a Unicode object unicode and return the result as Python
          object. */
        /// Deprecated in 3.6
        deprecated("Deprecated in 3.6")
        PyObject* PyUnicode_AsDecodedObject(
                PyObject* unicode,
                const(char)* encoding,
                const(char)* errors
                );
        /** Decode a Unicode object unicode and return the result as Unicode
          object. */
        /// Availability: 3.*

        /// Deprecated in 3.6
        deprecated("Deprecated in 3.6")
        PyObject* PyUnicode_AsDecodedUnicode(
                PyObject* unicode,
                const(char)* encoding,
                const(char)* errors
                );
    }else version(Python_3_0_Or_Later) {
        /** Decode a Unicode object unicode and return the result as Python
          object. */
            /// Availability: 3.*
        PyObject* PyUnicode_AsDecodedObject(
                PyObject* unicode,
                const(char)* encoding,
                const(char)* errors
                );
        /** Decode a Unicode object unicode and return the result as Unicode
          object. */
            /// Availability: 3.*

        PyObject* PyUnicode_AsDecodedUnicode(
                PyObject* unicode,
                const(char)* encoding,
                const(char)* errors
                );
    }

    /** Encodes a Py_UNICODE buffer of the given size and returns a
      Python string object.
Params:
s = Unicode char buffer
size = number of Py_UNICODE chars to encode
encoding = encoding
errors = error handling
     */
    PyObject* PyUnicode_Encode(
            Py_UNICODE* s,
            Py_ssize_t size,
            const(char)* encoding,
            const(char)* errors);

    version(Python_3_6_Or_Later) {
        /** Encodes a Unicode object and returns the result as Python object.
         */
        deprecated("Deprecated in 3.6")
        PyObject* PyUnicode_AsEncodedObject(
                PyObject* unicode,
                const(char)* encoding,
                const(char)* errors);
    }else{
        /** Encodes a Unicode object and returns the result as Python object.
         */
        PyObject* PyUnicode_AsEncodedObject(
                PyObject* unicode,
                const(char)* encoding,
                const(char)* errors);
    }

    /** Encodes a Unicode object and returns the result as Python string
      object. */
    PyObject* PyUnicode_AsEncodedString(
            PyObject* unicode,
            const(char)* encoding,
            const(char)* errors);

    version(Python_3_0_Or_Later) {
        /** Encodes a Unicode object and returns the result as Unicode
           object. */
        deprecated("Deprecated in 3.6")
        PyObject* PyUnicode_AsEncodedUnicode(
                PyObject* unicode,
                const(char)* encoding,
                const(char)* errors
                );
    }else version(Python_3_0_Or_Later) {
        /** Encodes a Unicode object and returns the result as Unicode
           object. */
        /// Availability: >= 3.*
        PyObject* PyUnicode_AsEncodedUnicode(
                PyObject* unicode,
                const(char)* encoding,
                const(char)* errors
                );
    }

    /**
Params:
    string = UTF-7 encoded string
    length = size of string
    errors = error handling
    */
    PyObject* PyUnicode_DecodeUTF7(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);

    /**
Params:
    data = Unicode char buffer
    length = number of Py_UNICODE chars to encode
    base64SetO = Encode RFC2152 Set O characters in base64
    base64WhiteSpace = Encode whitespace (sp, ht, nl, cr) in base64
    errors = error handling
    */
    PyObject* PyUnicode_EncodeUTF7(
            Py_UNICODE* data,
            Py_ssize_t length,
            int encodeSetO,
            int encodeWhiteSpace,
            const(char)* errors
      );

    /// _
    PyObject* PyUnicode_DecodeUTF8(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
    /// _
    PyObject* PyUnicode_DecodeUTF8Stateful(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors,
            Py_ssize_t* consumed
      );
    /// _
    PyObject* PyUnicode_AsUTF8String(PyObject* unicode);
    /// _
    PyObject* PyUnicode_EncodeUTF8(
            Py_UNICODE* data,
            Py_ssize_t length,
            const(char) *errors);

    /** Decodes length bytes from a UTF-16 encoded buffer string and returns
      the corresponding Unicode object.

      errors (if non-NULL) defines the error handling. It defaults
      to "strict".

      If byteorder is non-NULL, the decoder starts decoding using the
      given byte order:

     *byteorder == -1: little endian
     *byteorder == 0:  native order
     *byteorder == 1:  big endian

     In native mode, the first two bytes of the stream are checked for a
     BOM mark. If found, the BOM mark is analysed, the byte order
     adjusted and the BOM skipped.  In the other modes, no BOM mark
     interpretation is done. After completion, *byteorder is set to the
     current byte order at the end of input data.

     If byteorder is NULL, the codec starts in native order mode.

     */
    PyObject* PyUnicode_DecodeUTF16(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors,
            int* byteorder);
    /**
Params:
string = UTF-16 encoded string
length = size of string
errors = error handling
byteorder = pointer to byteorder to use 0=native;-1=LE,1=BE; updated on exit
consumed = bytes consumed
        */
    PyObject* PyUnicode_DecodeUTF16Stateful(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors,
            int* byteorder,
            Py_ssize_t* consumed
      );
    /** Returns a Python string using the UTF-16 encoding in native byte
       order. The string always starts with a BOM mark.  */
    PyObject* PyUnicode_AsUTF16String(PyObject *unicode);
    /** Returns a Python string object holding the UTF-16 encoded value of
       the Unicode data.

       If byteorder is not 0, output is written according to the following
       byte order:

       byteorder == -1: little endian
       byteorder == 0:  native byte order (writes a BOM mark)
       byteorder == 1:  big endian

       If byteorder is 0, the output string will always start with the
       Unicode BOM mark (U+FEFF). In the other two modes, no BOM mark is
       prepended.

       Note that Py_UNICODE data is being interpreted as UTF-16 reduced to
       UCS-2. This trick makes it possible to add full UTF-16 capabilities
       at a later point without compromising the APIs.

     */
    PyObject* PyUnicode_EncodeUTF16(
            Py_UNICODE* data,
            Py_ssize_t length,
            const(char)* errors,
            int byteorder
      );

    /// _
    PyObject* PyUnicode_DecodeUnicodeEscape(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
    /// _
    PyObject* PyUnicode_AsUnicodeEscapeString(
            PyObject* unicode);
    /// _
    PyObject* PyUnicode_EncodeUnicodeEscape(
            Py_UNICODE* data,
            Py_ssize_t length);
    /**
Params:
string = Raw-Unicode-Escape encoded string
length = size of string
errors = error handling
    */
    PyObject* PyUnicode_DecodeRawUnicodeEscape(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
    /// _
    PyObject* PyUnicode_AsRawUnicodeEscapeString(PyObject* unicode);
    /// _
    PyObject* PyUnicode_EncodeRawUnicodeEscape(
            Py_UNICODE* data, Py_ssize_t length);

    /// _
    PyObject* _PyUnicode_DecodeUnicodeInternal(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);

    /**
Params:
string = Latin-1 encoded string
length = size of string
errors = error handling
     */
    PyObject* PyUnicode_DecodeLatin1(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
    /// _
    PyObject* PyUnicode_AsLatin1String(PyObject *unicode);
    /**
Params:
data = Unicode char buffer
length = Number of Py_UNICODE chars to encode
errors = error handling
    */
    PyObject* PyUnicode_EncodeLatin1(
            Py_UNICODE* data,
            Py_ssize_t length,
            const(char)* errors);

    /**
Params:
    data = Unicode char buffer
    length = Number of Py_UNICODE chars to encode
    errors = error handling
    */
    PyObject* PyUnicode_DecodeASCII(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
    /// _
    PyObject* PyUnicode_AsASCIIString(PyObject *unicode);
    /**
Params:
    data = Unicode char buffer
    length = Number of Py_UNICODE chars to encode
    errors = error handling
      */
    PyObject* PyUnicode_EncodeASCII(
            Py_UNICODE* data,
            Py_ssize_t length,
            const(char)* errors);

    /**
Params:
    string = Encoded string
    length = size of string
    mapping = character mapping (char ordinal -> unicode ordinal)
    errors = error handling
      */
    PyObject* PyUnicode_DecodeCharmap(
            const(char)* string,
            Py_ssize_t length,
            PyObject* mapping,
            const(char)* errors
      );
    /**
Params:
    unicode = Unicode object
    mapping = character mapping (unicode ordinal -> char ordinal)
      */
    PyObject* PyUnicode_AsCharmapString(
            PyObject* unicode,
            PyObject* mapping);
    /**
Params:
    data = Unicode char buffer
    length = Number of Py_UNICODE chars to encode
    mapping = character mapping (unicode ordinal -> char ordinal)
    errors = error handling
      */
    PyObject* PyUnicode_EncodeCharmap(
            Py_UNICODE* data,
            Py_ssize_t length,
            PyObject* mapping,
            const(char)* errors
      );
    /** Translate a Py_UNICODE buffer of the given length by applying a
      character mapping table to it and return the resulting Unicode
      object.

      The mapping table must map Unicode ordinal integers to Unicode
      ordinal integers or None (causing deletion of the character).

      Mapping tables may be dictionaries or sequences. Unmapped character
      ordinals (ones which cause a LookupError) are left untouched and
      are copied as-is.

     */
    PyObject* PyUnicode_TranslateCharmap(
            Py_UNICODE* data,
            Py_ssize_t length,
            PyObject* table,
            const(char)* errors
      );

    version (Windows) {
        /// Availability: Windows only
      PyObject* PyUnicode_DecodeMBCS(
              const(char)* string,
              Py_ssize_t length,
              const(char)* errors);
        /// Availability: Windows only
      PyObject* PyUnicode_AsMBCSString(PyObject* unicode);
        /// Availability: Windows only
      PyObject* PyUnicode_EncodeMBCS(
              Py_UNICODE* data,
              Py_ssize_t length,
              const(char)* errors);
    }
    /** Takes a Unicode string holding a decimal value and writes it into
      an output buffer using standard ASCII digit codes.

      The output buffer has to provide at least length+1 bytes of storage
      area. The output string is 0-terminated.

      The encoder converts whitespace to ' ', decimal characters to their
      corresponding ASCII digit and all other Latin-1 characters except
      \0 as-is. Characters outside this range (Unicode ordinals 1-256)
      are treated as errors. This includes embedded NULL bytes.

      Error handling is defined by the errors argument:

      NULL or "strict": raise a ValueError
      "ignore": ignore the wrong characters (these are not copied to the
      output buffer)
      "replace": replaces illegal characters with '?'

      Returns 0 on success, -1 on failure.

     */
    int PyUnicode_EncodeDecimal(
            Py_UNICODE* s,
            Py_ssize_t length,
            char* output,
            const(char)* errors);

    /** Concat two strings giving a new Unicode string. */
    PyObject* PyUnicode_Concat(
            PyObject* left,
            PyObject* right);

    version(Python_3_0_Or_Later) {
        /** Concat two strings and put the result in *pleft
           (sets *pleft to NULL on error)
Params:
pleft = Pointer to left string
right = Right string
         */
        /// Availability: 3.*

        void PyUnicode_Append(
                PyObject** pleft,
                PyObject* right
                );

        /** Concat two strings, put the result in *pleft and drop the right object
           (sets *pleft to NULL on error)
Params:
pleft = Pointer to left string
         */
        /// Availability: 3.*
        void PyUnicode_AppendAndDel(
                PyObject** pleft,
                PyObject* right
                );
    }

    /** Split a string giving a list of Unicode strings.

      If sep is NULL, splitting will be done at all whitespace
      substrings. Otherwise, splits occur at the given separator.

      At most maxsplit splits will be done. If negative, no limit is set.

      Separators are not included in the resulting list.

     */
    PyObject* PyUnicode_Split(
            PyObject* s,
            PyObject* sep,
            Py_ssize_t maxsplit);

    /** Ditto PyUnicode_Split, but split at line breaks.

       CRLF is considered to be one line break. Line breaks are not
       included in the resulting list. */
    PyObject* PyUnicode_Splitlines(
            PyObject* s,
            int keepends);

    version(Python_2_5_Or_Later) {
        /** Partition a string using a given separator. */
        /// Availability: >= 2.5
        PyObject* PyUnicode_Partition(
                PyObject* s,
                PyObject* sep
                );

        /** Partition a string using a given separator, searching from the end
          of the string. */

        PyObject* PyUnicode_RPartition(
                PyObject* s,
                PyObject* sep
                );
    }

    /** Split a string giving a list of Unicode strings.

       If sep is NULL, splitting will be done at all whitespace
       substrings. Otherwise, splits occur at the given separator.

       At most maxsplit splits will be done. But unlike PyUnicode_Split
       PyUnicode_RSplit splits from the end of the string. If negative,
       no limit is set.

       Separators are not included in the resulting list.

     */
    PyObject* PyUnicode_RSplit(
            PyObject* s,
            PyObject* sep,
            Py_ssize_t maxsplit);

    /** Translate a string by applying a character mapping table to it and
      return the resulting Unicode object.

      The mapping table must map Unicode ordinal integers to Unicode
      ordinal integers or None (causing deletion of the character).

      Mapping tables may be dictionaries or sequences. Unmapped character
      ordinals (ones which cause a LookupError) are left untouched and
      are copied as-is.

     */
    PyObject* PyUnicode_Translate(
            PyObject* str,
            PyObject* table,
            const(char)* errors);

    /** Join a sequence of strings using the given separator and return
      the resulting Unicode string. */
    PyObject* PyUnicode_Join(
            PyObject* separator,
            PyObject* seq);

    /** Return 1 if substr matches str[start:end] at the given tail end, 0
      otherwise. */
    Py_ssize_t PyUnicode_Tailmatch(
            PyObject* str,
            PyObject* substr,
            Py_ssize_t start,
            Py_ssize_t end,
            int direction
      );

    /** Return the first position of substr in str[start:end] using the
      given search direction or -1 if not found. -2 is returned in case
      an error occurred and an exception is set. */
    Py_ssize_t PyUnicode_Find(
            PyObject* str,
            PyObject* substr,
            Py_ssize_t start,
            Py_ssize_t end,
            int direction
      );

    /** Count the number of occurrences of substr in str[start:end]. */
    Py_ssize_t PyUnicode_Count(
            PyObject* str,
            PyObject* substr,
            Py_ssize_t start,
            Py_ssize_t end);

    /** Replace at most maxcount occurrences of substr in str with replstr
       and return the resulting Unicode object. */
    PyObject* PyUnicode_Replace(
            PyObject* str,
            PyObject* substr,
            PyObject* replstr,
            Py_ssize_t maxcount
      );

    /** Compare two strings and return -1, 0, 1 for less than, equal,
      greater than resp. */
    int PyUnicode_Compare(PyObject* left, PyObject* right);
    version(Python_3_0_Or_Later) {
        /** Compare two strings and return -1, 0, 1 for less than, equal,
          greater than resp.
Params:
left =
right = ASCII-encoded string
         */
        /// Availability: 3.*
        int PyUnicode_CompareWithASCIIString(
                PyObject* left,
                const(char)* right
                );
    }

    version(Python_2_5_Or_Later) {
        /** Rich compare two strings and return one of the following:

          - NULL in case an exception was raised
          - Py_True or Py_False for successfuly comparisons
          - Py_NotImplemented in case the type combination is unknown

          Note that Py_EQ and Py_NE comparisons can cause a UnicodeWarning in
          case the conversion of the arguments to Unicode fails with a
          UnicodeDecodeError.

          Possible values for op:

          Py_GT, Py_GE, Py_EQ, Py_NE, Py_LT, Py_LE

         */
        /// Availability: >= 2.5
        PyObject* PyUnicode_RichCompare(
                PyObject* left,
                PyObject* right,
                int op
                );
    }

    /** Apply a argument tuple or dictionary to a format string and return
      the resulting Unicode string. */
    PyObject* PyUnicode_Format(PyObject* format, PyObject* args);

    /** Checks whether element is contained in container and return 1/0
       accordingly.

       element has to coerce to an one element Unicode string. -1 is
       returned in case of an error. */
    int PyUnicode_Contains(PyObject* container, PyObject* element);

    version(Python_3_0_Or_Later) {
        /** Checks whether argument is a valid identifier. */
        /// Availability: 3.*
        int PyUnicode_IsIdentifier(PyObject* s);
    }


    /// _
    int _PyUnicode_IsLowercase(Py_UNICODE ch);
    /// _
    int _PyUnicode_IsUppercase(Py_UNICODE ch);
    /// _
    int _PyUnicode_IsTitlecase(Py_UNICODE ch);
    /// _
    int _PyUnicode_IsWhitespace(Py_UNICODE ch);
    /// _
    int _PyUnicode_IsLinebreak(Py_UNICODE ch);
    /// _
    Py_UNICODE _PyUnicode_ToLowercase(Py_UNICODE ch);
    /// _
    Py_UNICODE _PyUnicode_ToUppercase(Py_UNICODE ch);
    /// _
    Py_UNICODE _PyUnicode_ToTitlecase(Py_UNICODE ch);
    /// _
    int _PyUnicode_ToDecimalDigit(Py_UNICODE ch);
    /// _
    int _PyUnicode_ToDigit(Py_UNICODE ch);
    /// _
    double _PyUnicode_ToNumeric(Py_UNICODE ch);
    /// _
    int _PyUnicode_IsDecimalDigit(Py_UNICODE ch);
    /// _
    int _PyUnicode_IsDigit(Py_UNICODE ch);
    /// _
    int _PyUnicode_IsNumeric(Py_UNICODE ch);
    /// _
    int _PyUnicode_IsAlpha(Py_UNICODE ch);

  };

/*
pragma(msg,substitute_and_alias(unicode_funs));
mixin(substitute_and_alias(unicode_funs));
*/

// waaaa! calling substitute_and_alias breaks linking!
// oh, well. this is probably faster anyways.
// following code is generated by substitute_and_alias.
// don't modify it; modify unicode_funs!
version(Python_3_3_Or_Later) {
    version(Python_2_6_Or_Later) {

    /** Create a Unicode Object from the Py_UNICODE buffer u of the given
       size.

       u may be NULL which causes the contents to be undefined. It is the
       user's responsibility to fill in the needed data afterwards. Note
       that modifying the Unicode object contents after construction is
       only allowed if u was set to NULL.

       The buffer is copied into the new object. */
        /// Availability: >= 2.6
        PyObject* PyUnicode_FromUnicode(Py_UNICODE* u, Py_ssize_t size);

      /** Similar to PyUnicode_FromUnicode(), but u points to Latin-1 encoded bytes */
        /// Availability: >= 2.6
      PyObject* PyUnicode_FromStringAndSize(
              const(char)*u,        /* char buffer */
              Py_ssize_t size       /* size of buffer */
              );

      /** Similar to PyUnicode_FromUnicode(), but u points to null-terminated
         Latin-1 encoded bytes */
        /// Availability: >= 2.6
      PyObject* PyUnicode_FromString(
              const(char)*u        /* string */
              );

        /// Availability: >= 2.6
      PyObject* PyUnicode_FromFormatV(const(char)*, va_list);

        /// Availability: >= 2.6
      PyObject* PyUnicode_FromFormat(const(char)*, ...);

      /** Format the object based on the format_spec, as defined in PEP 3101
         (Advanced String Formatting). */
        /// Availability: >= 2.6
      PyObject* _PyUnicode_FormatAdvanced(PyObject *obj,
              Py_UNICODE *format_spec,
              Py_ssize_t format_spec_len);

        /// Availability: >= 2.6
      int PyUnicode_ClearFreeList();

      /**
Params:
string = UTF-7 encoded string
length = size of string
error = error handling
consumed = bytes consumed
*/
        /// Availability: >= 2.6
      PyObject* PyUnicode_DecodeUTF7Stateful(
              const(char)* string,
              Py_ssize_t length,
              const(char)*errors,
              Py_ssize_t *consumed
              );

      /**
Params:
string = UTF-32 encoded string
length = size of string
error = error handling
byteorder = pointer to byteorder to use 0=native;-1=LE,1=BE; updated on exit
*/
        /// Availability: >= 2.6
      PyObject* PyUnicode_DecodeUTF32(
              const(char)* string,
              Py_ssize_t length,
              const(char)*errors,
              int *byteorder
              );

      /**
Params:
string = UTF-32 encoded string
length = size of string
error = error handling
byteorder = pointer to byteorder to use 0=native;-1=LE,1=BE; updated on exit
*/
        /// Availability: >= 2.6
      PyObject* PyUnicode_DecodeUTF32Stateful(
              const(char)*string,
              Py_ssize_t length,
              const(char)*errors,
              int *byteorder,
              Py_ssize_t *consumed
              );

      /** Returns a Python string using the UTF-32 encoding in native byte
         order. The string always starts with a BOM mark.  */
        /// Availability: >= 2.6

      PyObject* PyUnicode_AsUTF32String(
              PyObject *unicode
              );

      /** Returns a Python string object holding the UTF-32 encoded value of
         the Unicode data.

         If byteorder is not 0, output is written according to the following
         byte order:

         byteorder == -1: little endian
         byteorder == 0:  native byte order (writes a BOM mark)
         byteorder == 1:  big endian

         If byteorder is 0, the output string will always start with the
         Unicode BOM mark (U+FEFF). In the other two modes, no BOM mark is
         prepended.
Params:
data = Unicode char buffer
length = number of Py_UNICODE chars to encode
errors = error handling
byteorder = byteorder to use 0=BOM+native;-1=LE,1=BE

       */
        /// Availability: >= 2.6
      PyObject* PyUnicode_EncodeUTF32(
              const Py_UNICODE *data,
              Py_ssize_t length,
              const(char)* errors,
              int byteorder
              );

      }

    /** Return a read-only pointer to the Unicode object's internal
      Py_UNICODE buffer. */
    Py_UNICODE* PyUnicode_AsUnicode(PyObject* unicode);

    /** Get the length of the Unicode object. */
    Py_ssize_t PyUnicode_GetSize(PyObject* unicode);

    /** Get the maximum ordinal for a Unicode character. */
    Py_UNICODE PyUnicode_GetMax();

    /** Resize an already allocated Unicode object to the new size length.

   _*unicode is modified to point to the new (resized) object and 0
   returned on success.

   This API may only be called by the function which also called the
   Unicode constructor. The refcount on the object must be 1. Otherwise,
   an error is returned.

   Error handling is implemented as follows: an exception is set, -1
   is returned and *unicode left untouched.
Params:
unicode = pointer to the new unicode object.
length = New length.

*/
    int PyUnicode_Resize(PyObject** unicode, Py_ssize_t length);

    /** Coerce obj to an Unicode object and return a reference with
     _*incremented* refcount.

     Coercion is done in the following way:

     1. String and other char buffer compatible objects are decoded
     under the assumptions that they contain data using the current
     default encoding. Decoding is done in "strict" mode.

     2. All other objects (including Unicode objects) raise an
     exception.

     The API returns NULL in case of an error. The caller is responsible
     for decref'ing the returned objects.

     */
    PyObject* PyUnicode_FromEncodedObject(
            PyObject* obj,
            const(char)* encoding,
            const(char)* errors);

    /** Coerce obj to an Unicode object and return a reference with
     _*incremented* refcount.

     Unicode objects are passed back as-is (subclasses are converted to
     true Unicode objects), all other objects are delegated to
     PyUnicode_FromEncodedObject(obj, NULL, "strict") which results in
     using the default encoding as basis for decoding the object.

     The API returns NULL in case of an error. The caller is responsible
     for decref'ing the returned objects.

     */
    PyObject* PyUnicode_FromObject(PyObject* obj);

    /** Create a Unicode Object from the whcar_t buffer w of the given
      size.

      The buffer is copied into the new object. */
    PyObject* PyUnicode_FromWideChar(const(wchar)* w, Py_ssize_t size);

    /** Copies the Unicode Object contents into the wchar_t buffer w.  At
      most size wchar_t characters are copied.

      Note that the resulting wchar_t string may or may not be
      0-terminated.  It is the responsibility of the caller to make sure
      that the wchar_t string is 0-terminated in case this is required by
      the application.

      Returns the number of wchar_t characters copied (excluding a
      possibly trailing 0-termination character) or -1 in case of an
      error. */
    Py_ssize_t PyUnicode_AsWideChar(
            PyUnicodeObject* unicode,
            const(wchar)* w,
            Py_ssize_t size);

    /** Create a Unicode Object from the given Unicode code point ordinal.

       The ordinal must be in range(0x10000) on narrow Python builds
       (UCS2), and range(0x110000) on wide builds (UCS4). A ValueError is
       raised in case it is not.

     */
    PyObject* PyUnicode_FromOrdinal(int ordinal);

    /** Return a Python string holding the default encoded value of the
      Unicode object.

      The resulting string is cached in the Unicode object for subsequent
      usage by this function. The cached version is needed to implement
      the character buffer interface and will live (at least) as long as
      the Unicode object itself.

      The refcount of the string is *not* incremented.

     _*** Exported for internal use by the interpreter only !!! ***

     */
    PyObject* _PyUnicode_AsDefaultEncodedString(PyObject *, const(char)*);

    /** Returns the currently active default encoding.

      The default encoding is currently implemented as run-time settable
      process global.  This may change in future versions of the
      interpreter to become a parameter which is managed on a per-thread
      basis.

     */
    const(char)* PyUnicode_GetDefaultEncoding();

    /** Sets the currently active default encoding.

       Returns 0 on success, -1 in case of an error.

     */
    int PyUnicode_SetDefaultEncoding(const(char)*encoding);

    /** Create a Unicode object by decoding the encoded string s of the
      given size.
Params:
s = encoded string
size = size of buffer
encoding = encoding
errors = error handling
     */
    PyObject* PyUnicode_Decode(
            const(char)* s,
            Py_ssize_t size,
            const(char)* encoding,
            const(char)* errors);

    version(Python_3_0_Or_Later) {
    /** Decode a Unicode object unicode and return the result as Python
      object. */
        /// Availability: 3.*

    PyObject* PyUnicode_AsDecodedObject(
            PyObject* unicode,
            const(char)* encoding,
            const(char)* errors
            );

    /** Decode a Unicode object unicode and return the result as Unicode
      object. */
        /// Availability: 3.*

    PyObject* PyUnicode_AsDecodedUnicode(
            PyObject* unicode,
            const(char)* encoding,
            const(char)* errors
            );

    }

    /** Encodes a Py_UNICODE buffer of the given size and returns a
      Python string object.
Params:
s = Unicode char buffer
size = number of Py_UNICODE chars to encode
encoding = encoding
errors = error handling
     */
    PyObject* PyUnicode_Encode(
            Py_UNICODE* s,
            Py_ssize_t size,
            const(char)* encoding,
            const(char)* errors);

    /** Encodes a Unicode object and returns the result as Python object.
     */
    PyObject* PyUnicode_AsEncodedObject(
            PyObject* unicode,
            const(char)* encoding,
            const(char)* errors);

    /** Encodes a Unicode object and returns the result as Python string
      object. */
    PyObject* PyUnicode_AsEncodedString(
            PyObject* unicode,
            const(char)* encoding,
            const(char)* errors);

    version(Python_3_0_Or_Later) {
        /** Encodes a Unicode object and returns the result as Unicode
           object. */
        /// Availability: >= 3.*
        PyObject* PyUnicode_AsEncodedUnicode(
                PyObject* unicode,
                const(char)* encoding,
                const(char)* errors
                );

    }

    /**
Params:
    string = UTF-7 encoded string
    length = size of string
    errors = error handling
    */
    PyObject* PyUnicode_DecodeUTF7(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);

    /**
Params:
    data = Unicode char buffer
    length = number of Py_UNICODE chars to encode
    base64SetO = Encode RFC2152 Set O characters in base64
    base64WhiteSpace = Encode whitespace (sp, ht, nl, cr) in base64
    errors = error handling
    */
    PyObject* PyUnicode_EncodeUTF7(
            Py_UNICODE* data,
            Py_ssize_t length,
            int encodeSetO,
            int encodeWhiteSpace,
            const(char)* errors
      );

    /// _
    PyObject* PyUnicode_DecodeUTF8(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);

    /// _
    PyObject* PyUnicode_DecodeUTF8Stateful(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors,
            Py_ssize_t* consumed
      );

    /// _
    PyObject* PyUnicode_AsUTF8String(PyObject* unicode);

    /// _
    PyObject* PyUnicode_EncodeUTF8(
            Py_UNICODE* data,
            Py_ssize_t length,
            const(char) *errors);



    /** Decodes length bytes from a UTF-16 encoded buffer string and returns
      the corresponding Unicode object.

      errors (if non-NULL) defines the error handling. It defaults
      to "strict".

      If byteorder is non-NULL, the decoder starts decoding using the
      given byte order:

     *byteorder == -1: little endian
     *byteorder == 0:  native order
     *byteorder == 1:  big endian

     In native mode, the first two bytes of the stream are checked for a
     BOM mark. If found, the BOM mark is analysed, the byte order
     adjusted and the BOM skipped.  In the other modes, no BOM mark
     interpretation is done. After completion, *byteorder is set to the
     current byte order at the end of input data.

     If byteorder is NULL, the codec starts in native order mode.

     */
    PyObject* PyUnicode_DecodeUTF16(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors,
            int* byteorder);


    /**
Params:
string = UTF-16 encoded string
length = size of string
errors = error handling
byteorder = pointer to byteorder to use 0=native;-1=LE,1=BE; updated on exit
consumed = bytes consumed
        */
    PyObject* PyUnicode_DecodeUTF16Stateful(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors,
            int* byteorder,
            Py_ssize_t* consumed
      );


    /** Returns a Python string using the UTF-16 encoding in native byte
       order. The string always starts with a BOM mark.  */
    PyObject* PyUnicode_AsUTF16String(PyObject *unicode);


    /** Returns a Python string object holding the UTF-16 encoded value of
       the Unicode data.

       If byteorder is not 0, output is written according to the following
       byte order:

       byteorder == -1: little endian
       byteorder == 0:  native byte order (writes a BOM mark)
       byteorder == 1:  big endian

       If byteorder is 0, the output string will always start with the
       Unicode BOM mark (U+FEFF). In the other two modes, no BOM mark is
       prepended.

       Note that Py_UNICODE data is being interpreted as UTF-16 reduced to
       UCS-2. This trick makes it possible to add full UTF-16 capabilities
       at a later point without compromising the APIs.

     */
    PyObject* PyUnicode_EncodeUTF16(
            Py_UNICODE* data,
            Py_ssize_t length,
            const(char)* errors,
            int byteorder
      );



    /// _
    PyObject* PyUnicode_DecodeUnicodeEscape(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);


    /// _
    PyObject* PyUnicode_AsUnicodeEscapeString(
            PyObject* unicode);


    /// _
    PyObject* PyUnicode_EncodeUnicodeEscape(
            Py_UNICODE* data,
            Py_ssize_t length);


    /**
Params:
string = Raw-Unicode-Escape encoded string
length = size of string
errors = error handling
    */
    PyObject* PyUnicode_DecodeRawUnicodeEscape(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);

    /// _
    PyObject* PyUnicode_AsRawUnicodeEscapeString(PyObject* unicode);

    /// _
    PyObject* PyUnicode_EncodeRawUnicodeEscape(
            Py_UNICODE* data, Py_ssize_t length);

    /// _
    PyObject* _PyUnicode_DecodeUnicodeInternal(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);

    /**
Params:
string = Latin-1 encoded string
length = size of string
errors = error handling
     */
    PyObject* PyUnicode_DecodeLatin1(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);

    /// _
    PyObject* PyUnicode_AsLatin1String(PyObject *unicode);

    /**
Params:
data = Unicode char buffer
length = Number of Py_UNICODE chars to encode
errors = error handling
    */
    PyObject* PyUnicode_EncodeLatin1(
            Py_UNICODE* data,
            Py_ssize_t length,
            const(char)* errors);

    /**
Params:
    data = Unicode char buffer
    length = Number of Py_UNICODE chars to encode
    errors = error handling
    */
    PyObject* PyUnicode_DecodeASCII(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);

    /// _
    PyObject* PyUnicode_AsASCIIString(PyObject *unicode);

    /**
Params:
    data = Unicode char buffer
    length = Number of Py_UNICODE chars to encode
    errors = error handling
      */
    PyObject* PyUnicode_EncodeASCII(
            Py_UNICODE* data,
            Py_ssize_t length,
            const(char)* errors);

    /**
Params:
    string = Encoded string
    length = size of string
    mapping = character mapping (char ordinal -> unicode ordinal)
    errors = error handling
      */
    PyObject* PyUnicode_DecodeCharmap(
            const(char)* string,
            Py_ssize_t length,
            PyObject* mapping,
            const(char)* errors
      );

    /**
Params:
    unicode = Unicode object
    mapping = character mapping (unicode ordinal -> char ordinal)
      */
    PyObject* PyUnicode_AsCharmapString(
            PyObject* unicode,
            PyObject* mapping);

    /**
Params:
    data = Unicode char buffer
    length = Number of Py_UNICODE chars to encode
    mapping = character mapping (unicode ordinal -> char ordinal)
    errors = error handling
      */
    PyObject* PyUnicode_EncodeCharmap(
            Py_UNICODE* data,
            Py_ssize_t length,
            PyObject* mapping,
            const(char)* errors
      );

    /** Translate a Py_UNICODE buffer of the given length by applying a
      character mapping table to it and return the resulting Unicode
      object.

      The mapping table must map Unicode ordinal integers to Unicode
      ordinal integers or None (causing deletion of the character).

      Mapping tables may be dictionaries or sequences. Unmapped character
      ordinals (ones which cause a LookupError) are left untouched and
      are copied as-is.

     */
    PyObject* PyUnicode_TranslateCharmap(
            Py_UNICODE* data,
            Py_ssize_t length,
            PyObject* table,
            const(char)* errors
      );

    version (Windows) {
        /// Availability: Windows only
      PyObject* PyUnicode_DecodeMBCS(
              const(char)* string,
              Py_ssize_t length,
              const(char)* errors);

        /// Availability: Windows only
      PyObject* PyUnicode_AsMBCSString(PyObject* unicode);

        /// Availability: Windows only
      PyObject* PyUnicode_EncodeMBCS(
              Py_UNICODE* data,
              Py_ssize_t length,
              const(char)* errors);

    }
    /** Takes a Unicode string holding a decimal value and writes it into
      an output buffer using standard ASCII digit codes.

      The output buffer has to provide at least length+1 bytes of storage
      area. The output string is 0-terminated.

      The encoder converts whitespace to ' ', decimal characters to their
      corresponding ASCII digit and all other Latin-1 characters except
      \0 as-is. Characters outside this range (Unicode ordinals 1-256)
      are treated as errors. This includes embedded NULL bytes.

      Error handling is defined by the errors argument:

      NULL or "strict": raise a ValueError
      "ignore": ignore the wrong characters (these are not copied to the
      output buffer)
      "replace": replaces illegal characters with '?'

      Returns 0 on success, -1 on failure.

     */
    int PyUnicode_EncodeDecimal(
            Py_UNICODE* s,
            Py_ssize_t length,
            char* output,
            const(char)* errors);

    /** Concat two strings giving a new Unicode string. */
    PyObject* PyUnicode_Concat(
            PyObject* left,
            PyObject* right);

    version(Python_3_0_Or_Later) {
        /** Concat two strings and put the result in *pleft
           (sets *pleft to NULL on error)
Params:
pleft = Pointer to left string
right = Right string
         */
        /// Availability: 3.*

        void PyUnicode_Append(
                PyObject** pleft,
                PyObject* right
                );

        /** Concat two strings, put the result in *pleft and drop the right object
           (sets *pleft to NULL on error)
Params:
pleft = Pointer to left string
         */
        /// Availability: 3.*
        void PyUnicode_AppendAndDel(
                PyObject** pleft,
                PyObject* right
                );

    }

    /** Split a string giving a list of Unicode strings.

      If sep is NULL, splitting will be done at all whitespace
      substrings. Otherwise, splits occur at the given separator.

      At most maxsplit splits will be done. If negative, no limit is set.

      Separators are not included in the resulting list.

     */
    PyObject* PyUnicode_Split(
            PyObject* s,
            PyObject* sep,
            Py_ssize_t maxsplit);

    /** Ditto PyUnicode_Split, but split at line breaks.

       CRLF is considered to be one line break. Line breaks are not
       included in the resulting list. */
    PyObject* PyUnicode_Splitlines(
            PyObject* s,
            int keepends);

    version(Python_2_5_Or_Later) {
        /** Partition a string using a given separator. */
        /// Availability: >= 2.5
        PyObject* PyUnicode_Partition(
                PyObject* s,
                PyObject* sep
                );


        /** Partition a string using a given separator, searching from the end
          of the string. */

        PyObject* PyUnicode_RPartition(
                PyObject* s,
                PyObject* sep
                );

    }

    /** Split a string giving a list of Unicode strings.

       If sep is NULL, splitting will be done at all whitespace
       substrings. Otherwise, splits occur at the given separator.

       At most maxsplit splits will be done. But unlike PyUnicode_Split
       PyUnicode_RSplit splits from the end of the string. If negative,
       no limit is set.

       Separators are not included in the resulting list.

     */
    PyObject* PyUnicode_RSplit(
            PyObject* s,
            PyObject* sep,
            Py_ssize_t maxsplit);


    /** Translate a string by applying a character mapping table to it and
      return the resulting Unicode object.

      The mapping table must map Unicode ordinal integers to Unicode
      ordinal integers or None (causing deletion of the character).

      Mapping tables may be dictionaries or sequences. Unmapped character
      ordinals (ones which cause a LookupError) are left untouched and
      are copied as-is.

     */
    PyObject* PyUnicode_Translate(
            PyObject* str,
            PyObject* table,
            const(char)* errors);

    /** Join a sequence of strings using the given separator and return
      the resulting Unicode string. */
    PyObject* PyUnicode_Join(
            PyObject* separator,
            PyObject* seq);

    /** Return 1 if substr matches str[start:end] at the given tail end, 0
      otherwise. */
    Py_ssize_t PyUnicode_Tailmatch(
            PyObject* str,
            PyObject* substr,
            Py_ssize_t start,
            Py_ssize_t end,
            int direction
      );


    /** Return the first position of substr in str[start:end] using the
      given search direction or -1 if not found. -2 is returned in case
      an error occurred and an exception is set. */
    Py_ssize_t PyUnicode_Find(
            PyObject* str,
            PyObject* substr,
            Py_ssize_t start,
            Py_ssize_t end,
            int direction
      );

    /** Count the number of occurrences of substr in str[start:end]. */
    Py_ssize_t PyUnicode_Count(
            PyObject* str,
            PyObject* substr,
            Py_ssize_t start,
            Py_ssize_t end);

    /** Replace at most maxcount occurrences of substr in str with replstr
       and return the resulting Unicode object. */
    PyObject* PyUnicode_Replace(
            PyObject* str,
            PyObject* substr,
            PyObject* replstr,
            Py_ssize_t maxcount
      );

    /** Compare two strings and return -1, 0, 1 for less than, equal,
      greater than resp. */
    int PyUnicode_Compare(PyObject* left, PyObject* right);

    version(Python_3_0_Or_Later) {
        /** Compare two strings and return -1, 0, 1 for less than, equal,
          greater than resp.
Params:
left =
right = ASCII-encoded string
         */
        /// Availability: 3.*
        int PyUnicode_CompareWithASCIIString(
                PyObject* left,
                const(char)* right
                );
    }

    version(Python_2_5_Or_Later) {
        /** Rich compare two strings and return one of the following:

          - NULL in case an exception was raised
          - Py_True or Py_False for successfuly comparisons
          - Py_NotImplemented in case the type combination is unknown

          Note that Py_EQ and Py_NE comparisons can cause a UnicodeWarning in
          case the conversion of the arguments to Unicode fails with a
          UnicodeDecodeError.

          Possible values for op:

          Py_GT, Py_GE, Py_EQ, Py_NE, Py_LT, Py_LE

         */
        /// Availability: >= 2.5
        PyObject* PyUnicode_RichCompare(
                PyObject* left,
                PyObject* right,
                int op
                );
    }

    /** Apply a argument tuple or dictionary to a format string and return
      the resulting Unicode string. */
    PyObject* PyUnicode_Format(PyObject* format, PyObject* args);

    /** Checks whether element is contained in container and return 1/0
       accordingly.

       element has to coerce to an one element Unicode string. -1 is
       returned in case of an error. */
    int PyUnicode_Contains(PyObject* container, PyObject* element);

    version(Python_3_0_Or_Later) {
        /** Checks whether argument is a valid identifier. */
        /// Availability: 3.*
        int PyUnicode_IsIdentifier(PyObject* s);
    }


    /// _
    int _PyUnicode_IsLowercase(Py_UNICODE ch);

    /// _
    int _PyUnicode_IsUppercase(Py_UNICODE ch);

    /// _
    int _PyUnicode_IsTitlecase(Py_UNICODE ch);

    /// _
    int _PyUnicode_IsWhitespace(Py_UNICODE ch);

    /// _
    int _PyUnicode_IsLinebreak(Py_UNICODE ch);

    /// _
    Py_UNICODE _PyUnicode_ToLowercase(Py_UNICODE ch);

    /// _
    Py_UNICODE _PyUnicode_ToUppercase(Py_UNICODE ch);

    /// _
    Py_UNICODE _PyUnicode_ToTitlecase(Py_UNICODE ch);

    /// _
    int _PyUnicode_ToDecimalDigit(Py_UNICODE ch);

    /// _
    int _PyUnicode_ToDigit(Py_UNICODE ch);

    /// _
    double _PyUnicode_ToNumeric(Py_UNICODE ch);

    /// _
    int _PyUnicode_IsDecimalDigit(Py_UNICODE ch);

    /// _
    int _PyUnicode_IsDigit(Py_UNICODE ch);

    /// _
    int _PyUnicode_IsNumeric(Py_UNICODE ch);

    /// _
    int _PyUnicode_IsAlpha(Py_UNICODE ch);

}else version(Python_Unicode_UCS2) {

    version(Python_2_6_Or_Later) {

    /** Create a Unicode Object from the Py_UNICODE buffer u of the given
       size.

       u may be NULL which causes the contents to be undefined. It is the
       user's responsibility to fill in the needed data afterwards. Note
       that modifying the Unicode object contents after construction is
       only allowed if u was set to NULL.

       The buffer is copied into the new object. */
        /// Availability: >= 2.6
        PyObject* PyUnicodeUCS2_FromUnicode(Py_UNICODE* u, Py_ssize_t size);
 /// ditto

alias PyUnicodeUCS2_FromUnicode PyUnicode_FromUnicode;


      /** Similar to PyUnicode_FromUnicode(), but u points to Latin-1 encoded bytes */
        /// Availability: >= 2.6
      PyObject* PyUnicodeUCS2_FromStringAndSize(
              const(char)*u,        /* char buffer */
              Py_ssize_t size       /* size of buffer */
              );
 /// ditto

alias PyUnicodeUCS2_FromStringAndSize PyUnicode_FromStringAndSize;


      /** Similar to PyUnicode_FromUnicode(), but u points to null-terminated
         Latin-1 encoded bytes */
        /// Availability: >= 2.6
      PyObject* PyUnicodeUCS2_FromString(
              const(char)*u        /* string */
              );
 /// ditto

alias PyUnicodeUCS2_FromString PyUnicode_FromString;

        /// Availability: >= 2.6
      PyObject* PyUnicodeUCS2_FromFormatV(const(char)*, va_list);
 /// ditto

alias PyUnicodeUCS2_FromFormatV PyUnicode_FromFormatV;

        /// Availability: >= 2.6
      PyObject* PyUnicodeUCS2_FromFormat(const(char)*, ...);
 /// ditto

alias PyUnicodeUCS2_FromFormat PyUnicode_FromFormat;


      /** Format the object based on the format_spec, as defined in PEP 3101
         (Advanced String Formatting). */
        /// Availability: >= 2.6
      PyObject* _PyUnicodeUCS2_FormatAdvanced(PyObject *obj,
              Py_UNICODE *format_spec,
              Py_ssize_t format_spec_len);
 /// ditto

alias _PyUnicodeUCS2_FormatAdvanced _PyUnicode_FormatAdvanced;

        /// Availability: >= 2.6
      int PyUnicodeUCS2_ClearFreeList();
 /// ditto

alias PyUnicodeUCS2_ClearFreeList PyUnicode_ClearFreeList;

      /**
Params:
string = UTF-7 encoded string
length = size of string
error = error handling
consumed = bytes consumed
*/
        /// Availability: >= 2.6
      PyObject* PyUnicodeUCS2_DecodeUTF7Stateful(
              const(char)* string,
              Py_ssize_t length,
              const(char)*errors,
              Py_ssize_t *consumed
              );
 /// ditto

alias PyUnicodeUCS2_DecodeUTF7Stateful PyUnicode_DecodeUTF7Stateful;

      /**
Params:
string = UTF-32 encoded string
length = size of string
error = error handling
byteorder = pointer to byteorder to use 0=native;-1=LE,1=BE; updated on exit
*/
        /// Availability: >= 2.6
      PyObject* PyUnicodeUCS2_DecodeUTF32(
              const(char)* string,
              Py_ssize_t length,
              const(char)*errors,
              int *byteorder
              );
 /// ditto

alias PyUnicodeUCS2_DecodeUTF32 PyUnicode_DecodeUTF32;


      /**
Params:
string = UTF-32 encoded string
length = size of string
error = error handling
byteorder = pointer to byteorder to use 0=native;-1=LE,1=BE; updated on exit
*/
        /// Availability: >= 2.6
      PyObject* PyUnicodeUCS2_DecodeUTF32Stateful(
              const(char)*string,
              Py_ssize_t length,
              const(char)*errors,
              int *byteorder,
              Py_ssize_t *consumed
              );
 /// ditto

alias PyUnicodeUCS2_DecodeUTF32Stateful PyUnicode_DecodeUTF32Stateful;

      /** Returns a Python string using the UTF-32 encoding in native byte
         order. The string always starts with a BOM mark.  */
        /// Availability: >= 2.6

      PyObject* PyUnicodeUCS2_AsUTF32String(
              PyObject *unicode
              );
 /// ditto

alias PyUnicodeUCS2_AsUTF32String PyUnicode_AsUTF32String;


      /** Returns a Python string object holding the UTF-32 encoded value of
         the Unicode data.

         If byteorder is not 0, output is written according to the following
         byte order:

         byteorder == -1: little endian
         byteorder == 0:  native byte order (writes a BOM mark)
         byteorder == 1:  big endian

         If byteorder is 0, the output string will always start with the
         Unicode BOM mark (U+FEFF). In the other two modes, no BOM mark is
         prepended.
Params:
data = Unicode char buffer
length = number of Py_UNICODE chars to encode
errors = error handling
byteorder = byteorder to use 0=BOM+native;-1=LE,1=BE

       */
        /// Availability: >= 2.6
      PyObject* PyUnicodeUCS2_EncodeUTF32(
              const Py_UNICODE *data,
              Py_ssize_t length,
              const(char)* errors,
              int byteorder
              );
 /// ditto

alias PyUnicodeUCS2_EncodeUTF32 PyUnicode_EncodeUTF32;

      }

    /** Return a read-only pointer to the Unicode object's internal
      Py_UNICODE buffer. */
    Py_UNICODE* PyUnicodeUCS2_AsUnicode(PyObject* unicode);
 /// ditto

alias PyUnicodeUCS2_AsUnicode PyUnicode_AsUnicode;

    /** Get the length of the Unicode object. */
    Py_ssize_t PyUnicodeUCS2_GetSize(PyObject* unicode);
 /// ditto

alias PyUnicodeUCS2_GetSize PyUnicode_GetSize;


    /** Get the maximum ordinal for a Unicode character. */
    Py_UNICODE PyUnicodeUCS2_GetMax();
 /// ditto

alias PyUnicodeUCS2_GetMax PyUnicode_GetMax;


    /** Resize an already allocated Unicode object to the new size length.

   _*unicode is modified to point to the new (resized) object and 0
   returned on success.

   This API may only be called by the function which also called the
   Unicode constructor. The refcount on the object must be 1. Otherwise,
   an error is returned.

   Error handling is implemented as follows: an exception is set, -1
   is returned and *unicode left untouched.
Params:
unicode = pointer to the new unicode object.
length = New length.

*/
    int PyUnicodeUCS2_Resize(PyObject** unicode, Py_ssize_t length);
 /// ditto

alias PyUnicodeUCS2_Resize PyUnicode_Resize;

    /** Coerce obj to an Unicode object and return a reference with
     _*incremented* refcount.

     Coercion is done in the following way:

     1. String and other char buffer compatible objects are decoded
     under the assumptions that they contain data using the current
     default encoding. Decoding is done in "strict" mode.

     2. All other objects (including Unicode objects) raise an
     exception.

     The API returns NULL in case of an error. The caller is responsible
     for decref'ing the returned objects.

     */
    PyObject* PyUnicodeUCS2_FromEncodedObject(
            PyObject* obj,
            const(char)* encoding,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_FromEncodedObject PyUnicode_FromEncodedObject;


    /** Coerce obj to an Unicode object and return a reference with
     _*incremented* refcount.

     Unicode objects are passed back as-is (subclasses are converted to
     true Unicode objects), all other objects are delegated to
     PyUnicode_FromEncodedObject(obj, NULL, "strict") which results in
     using the default encoding as basis for decoding the object.

     The API returns NULL in case of an error. The caller is responsible
     for decref'ing the returned objects.

     */
    PyObject* PyUnicodeUCS2_FromObject(PyObject* obj);
 /// ditto

alias PyUnicodeUCS2_FromObject PyUnicode_FromObject;


    /** Create a Unicode Object from the whcar_t buffer w of the given
      size.

      The buffer is copied into the new object. */
    PyObject* PyUnicodeUCS2_FromWideChar(const(wchar_t)* w, Py_ssize_t size);
 /// ditto

alias PyUnicodeUCS2_FromWideChar PyUnicode_FromWideChar;


    /** Copies the Unicode Object contents into the wchar_t buffer w.  At
      most size wchar_t characters are copied.

      Note that the resulting wchar_t string may or may not be
      0-terminated.  It is the responsibility of the caller to make sure
      that the wchar_t string is 0-terminated in case this is required by
      the application.

      Returns the number of wchar_t characters copied (excluding a
      possibly trailing 0-termination character) or -1 in case of an
      error. */
    Py_ssize_t PyUnicodeUCS2_AsWideChar(
            PyUnicodeObject* unicode,
            const(wchar_t)* w,
            Py_ssize_t size);
 /// ditto

alias PyUnicodeUCS2_AsWideChar PyUnicode_AsWideChar;


    /** Create a Unicode Object from the given Unicode code point ordinal.

       The ordinal must be in range(0x10000) on narrow Python builds
       (UCS2), and range(0x110000) on wide builds (UCS4). A ValueError is
       raised in case it is not.

     */
    PyObject* PyUnicodeUCS2_FromOrdinal(int ordinal);
 /// ditto

alias PyUnicodeUCS2_FromOrdinal PyUnicode_FromOrdinal;


    /** Return a Python string holding the default encoded value of the
      Unicode object.

      The resulting string is cached in the Unicode object for subsequent
      usage by this function. The cached version is needed to implement
      the character buffer interface and will live (at least) as long as
      the Unicode object itself.

      The refcount of the string is *not* incremented.

     _*** Exported for internal use by the interpreter only !!! ***

     */
    PyObject* _PyUnicodeUCS2_AsDefaultEncodedString(PyObject *, const(char)*);
 /// ditto

alias _PyUnicodeUCS2_AsDefaultEncodedString _PyUnicode_AsDefaultEncodedString;


    /** Returns the currently active default encoding.

      The default encoding is currently implemented as run-time settable
      process global.  This may change in future versions of the
      interpreter to become a parameter which is managed on a per-thread
      basis.

     */
    const(char)* PyUnicodeUCS2_GetDefaultEncoding();
 /// ditto

alias PyUnicodeUCS2_GetDefaultEncoding PyUnicode_GetDefaultEncoding;


    /** Sets the currently active default encoding.

       Returns 0 on success, -1 in case of an error.

     */
    int PyUnicodeUCS2_SetDefaultEncoding(const(char)*encoding);
 /// ditto

alias PyUnicodeUCS2_SetDefaultEncoding PyUnicode_SetDefaultEncoding;


    /** Create a Unicode object by decoding the encoded string s of the
      given size.
Params:
s = encoded string
size = size of buffer
encoding = encoding
errors = error handling
     */
    PyObject* PyUnicodeUCS2_Decode(
            const(char)* s,
            Py_ssize_t size,
            const(char)* encoding,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_Decode PyUnicode_Decode;


    version(Python_3_0_Or_Later) {
    /** Decode a Unicode object unicode and return the result as Python
      object. */
        /// Availability: 3.*

    PyObject* PyUnicodeUCS2_AsDecodedObject(
            PyObject* unicode,
            const(char)* encoding,
            const(char)* errors
            );
 /// ditto

alias PyUnicodeUCS2_AsDecodedObject PyUnicode_AsDecodedObject;

    /** Decode a Unicode object unicode and return the result as Unicode
      object. */
        /// Availability: 3.*

    PyObject* PyUnicodeUCS2_AsDecodedUnicode(
            PyObject* unicode,
            const(char)* encoding,
            const(char)* errors
            );
 /// ditto

alias PyUnicodeUCS2_AsDecodedUnicode PyUnicode_AsDecodedUnicode;

    }

    /** Encodes a Py_UNICODE buffer of the given size and returns a
      Python string object.
Params:
s = Unicode char buffer
size = number of Py_UNICODE chars to encode
encoding = encoding
errors = error handling
     */
    PyObject* PyUnicodeUCS2_Encode(
            Py_UNICODE* s,
            Py_ssize_t size,
            const(char)* encoding,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_Encode PyUnicode_Encode;


    /** Encodes a Unicode object and returns the result as Python object.
     */
    PyObject* PyUnicodeUCS2_AsEncodedObject(
            PyObject* unicode,
            const(char)* encoding,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_AsEncodedObject PyUnicode_AsEncodedObject;


    /** Encodes a Unicode object and returns the result as Python string
      object. */
    PyObject* PyUnicodeUCS2_AsEncodedString(
            PyObject* unicode,
            const(char)* encoding,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_AsEncodedString PyUnicode_AsEncodedString;


    version(Python_3_0_Or_Later) {
        /** Encodes a Unicode object and returns the result as Unicode
           object. */
        /// Availability: >= 3.*
        PyObject* PyUnicodeUCS2_AsEncodedUnicode(
                PyObject* unicode,
                const(char)* encoding,
                const(char)* errors
                );
 /// ditto

alias PyUnicodeUCS2_AsEncodedUnicode PyUnicode_AsEncodedUnicode;

    }

    /**
Params:
    string = UTF-7 encoded string
    length = size of string
    errors = error handling
    */
    PyObject* PyUnicodeUCS2_DecodeUTF7(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_DecodeUTF7 PyUnicode_DecodeUTF7;


    /**
Params:
    data = Unicode char buffer
    length = number of Py_UNICODE chars to encode
    base64SetO = Encode RFC2152 Set O characters in base64
    base64WhiteSpace = Encode whitespace (sp, ht, nl, cr) in base64
    errors = error handling
    */
    PyObject* PyUnicodeUCS2_EncodeUTF7(
            Py_UNICODE* data,
            Py_ssize_t length,
            int encodeSetO,
            int encodeWhiteSpace,
            const(char)* errors
      );
 /// ditto

alias PyUnicodeUCS2_EncodeUTF7 PyUnicode_EncodeUTF7;


    /// _
    PyObject* PyUnicodeUCS2_DecodeUTF8(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_DecodeUTF8 PyUnicode_DecodeUTF8;

    /// _
    PyObject* PyUnicodeUCS2_DecodeUTF8Stateful(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors,
            Py_ssize_t* consumed
      );
 /// ditto

alias PyUnicodeUCS2_DecodeUTF8Stateful PyUnicode_DecodeUTF8Stateful;

    /// _
    PyObject* PyUnicodeUCS2_AsUTF8String(PyObject* unicode);
 /// ditto

alias PyUnicodeUCS2_AsUTF8String PyUnicode_AsUTF8String;

    /// _
    PyObject* PyUnicodeUCS2_EncodeUTF8(
            Py_UNICODE* data,
            Py_ssize_t length,
            const(char) *errors);
 /// ditto

alias PyUnicodeUCS2_EncodeUTF8 PyUnicode_EncodeUTF8;


    /** Decodes length bytes from a UTF-16 encoded buffer string and returns
      the corresponding Unicode object.

      errors (if non-NULL) defines the error handling. It defaults
      to "strict".

      If byteorder is non-NULL, the decoder starts decoding using the
      given byte order:

     *byteorder == -1: little endian
     *byteorder == 0:  native order
     *byteorder == 1:  big endian

     In native mode, the first two bytes of the stream are checked for a
     BOM mark. If found, the BOM mark is analysed, the byte order
     adjusted and the BOM skipped.  In the other modes, no BOM mark
     interpretation is done. After completion, *byteorder is set to the
     current byte order at the end of input data.

     If byteorder is NULL, the codec starts in native order mode.

     */
    PyObject* PyUnicodeUCS2_DecodeUTF16(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors,
            int* byteorder);
 /// ditto

alias PyUnicodeUCS2_DecodeUTF16 PyUnicode_DecodeUTF16;

    /**
Params:
string = UTF-16 encoded string
length = size of string
errors = error handling
byteorder = pointer to byteorder to use 0=native;-1=LE,1=BE; updated on exit
consumed = bytes consumed
        */
    PyObject* PyUnicodeUCS2_DecodeUTF16Stateful(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors,
            int* byteorder,
            Py_ssize_t* consumed
      );
 /// ditto

alias PyUnicodeUCS2_DecodeUTF16Stateful PyUnicode_DecodeUTF16Stateful;

    /** Returns a Python string using the UTF-16 encoding in native byte
       order. The string always starts with a BOM mark.  */
    PyObject* PyUnicodeUCS2_AsUTF16String(PyObject *unicode);
 /// ditto

alias PyUnicodeUCS2_AsUTF16String PyUnicode_AsUTF16String;

    /** Returns a Python string object holding the UTF-16 encoded value of
       the Unicode data.

       If byteorder is not 0, output is written according to the following
       byte order:

       byteorder == -1: little endian
       byteorder == 0:  native byte order (writes a BOM mark)
       byteorder == 1:  big endian

       If byteorder is 0, the output string will always start with the
       Unicode BOM mark (U+FEFF). In the other two modes, no BOM mark is
       prepended.

       Note that Py_UNICODE data is being interpreted as UTF-16 reduced to
       UCS-2. This trick makes it possible to add full UTF-16 capabilities
       at a later point without compromising the APIs.

     */
    PyObject* PyUnicodeUCS2_EncodeUTF16(
            Py_UNICODE* data,
            Py_ssize_t length,
            const(char)* errors,
            int byteorder
      );
 /// ditto

alias PyUnicodeUCS2_EncodeUTF16 PyUnicode_EncodeUTF16;


    /// _
    PyObject* PyUnicodeUCS2_DecodeUnicodeEscape(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_DecodeUnicodeEscape PyUnicode_DecodeUnicodeEscape;

    /// _
    PyObject* PyUnicodeUCS2_AsUnicodeEscapeString(
            PyObject* unicode);
 /// ditto

alias PyUnicodeUCS2_AsUnicodeEscapeString PyUnicode_AsUnicodeEscapeString;

    /// _
    PyObject* PyUnicodeUCS2_EncodeUnicodeEscape(
            Py_UNICODE* data,
            Py_ssize_t length);
 /// ditto

alias PyUnicodeUCS2_EncodeUnicodeEscape PyUnicode_EncodeUnicodeEscape;

    /**
Params:
string = Raw-Unicode-Escape encoded string
length = size of string
errors = error handling
    */
    PyObject* PyUnicodeUCS2_DecodeRawUnicodeEscape(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_DecodeRawUnicodeEscape PyUnicode_DecodeRawUnicodeEscape;

    /// _
    PyObject* PyUnicodeUCS2_AsRawUnicodeEscapeString(PyObject* unicode);
 /// ditto

alias PyUnicodeUCS2_AsRawUnicodeEscapeString PyUnicode_AsRawUnicodeEscapeString;

    /// _
    PyObject* PyUnicodeUCS2_EncodeRawUnicodeEscape(
            Py_UNICODE* data, Py_ssize_t length);
 /// ditto

alias PyUnicodeUCS2_EncodeRawUnicodeEscape PyUnicode_EncodeRawUnicodeEscape;


    /// _
    PyObject* _PyUnicodeUCS2_DecodeUnicodeInternal(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias _PyUnicodeUCS2_DecodeUnicodeInternal _PyUnicode_DecodeUnicodeInternal;


    /**
Params:
string = Latin-1 encoded string
length = size of string
errors = error handling
     */
    PyObject* PyUnicodeUCS2_DecodeLatin1(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_DecodeLatin1 PyUnicode_DecodeLatin1;

    /// _
    PyObject* PyUnicodeUCS2_AsLatin1String(PyObject *unicode);
 /// ditto

alias PyUnicodeUCS2_AsLatin1String PyUnicode_AsLatin1String;

    /**
Params:
data = Unicode char buffer
length = Number of Py_UNICODE chars to encode
errors = error handling
    */
    PyObject* PyUnicodeUCS2_EncodeLatin1(
            Py_UNICODE* data,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_EncodeLatin1 PyUnicode_EncodeLatin1;


    /**
Params:
    data = Unicode char buffer
    length = Number of Py_UNICODE chars to encode
    errors = error handling
    */
    PyObject* PyUnicodeUCS2_DecodeASCII(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_DecodeASCII PyUnicode_DecodeASCII;

    /// _
    PyObject* PyUnicodeUCS2_AsASCIIString(PyObject *unicode);
 /// ditto

alias PyUnicodeUCS2_AsASCIIString PyUnicode_AsASCIIString;

    /**
Params:
    data = Unicode char buffer
    length = Number of Py_UNICODE chars to encode
    errors = error handling
      */
    PyObject* PyUnicodeUCS2_EncodeASCII(
            Py_UNICODE* data,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_EncodeASCII PyUnicode_EncodeASCII;


    /**
Params:
    string = Encoded string
    length = size of string
    mapping = character mapping (char ordinal -> unicode ordinal)
    errors = error handling
      */
    PyObject* PyUnicodeUCS2_DecodeCharmap(
            const(char)* string,
            Py_ssize_t length,
            PyObject* mapping,
            const(char)* errors
      );
 /// ditto

alias PyUnicodeUCS2_DecodeCharmap PyUnicode_DecodeCharmap;

    /**
Params:
    unicode = Unicode object
    mapping = character mapping (unicode ordinal -> char ordinal)
      */
    PyObject* PyUnicodeUCS2_AsCharmapString(
            PyObject* unicode,
            PyObject* mapping);
 /// ditto

alias PyUnicodeUCS2_AsCharmapString PyUnicode_AsCharmapString;

    /**
Params:
    data = Unicode char buffer
    length = Number of Py_UNICODE chars to encode
    mapping = character mapping (unicode ordinal -> char ordinal)
    errors = error handling
      */
    PyObject* PyUnicodeUCS2_EncodeCharmap(
            Py_UNICODE* data,
            Py_ssize_t length,
            PyObject* mapping,
            const(char)* errors
      );
 /// ditto

alias PyUnicodeUCS2_EncodeCharmap PyUnicode_EncodeCharmap;

    /** Translate a Py_UNICODE buffer of the given length by applying a
      character mapping table to it and return the resulting Unicode
      object.

      The mapping table must map Unicode ordinal integers to Unicode
      ordinal integers or None (causing deletion of the character).

      Mapping tables may be dictionaries or sequences. Unmapped character
      ordinals (ones which cause a LookupError) are left untouched and
      are copied as-is.

     */
    PyObject* PyUnicodeUCS2_TranslateCharmap(
            Py_UNICODE* data,
            Py_ssize_t length,
            PyObject* table,
            const(char)* errors
      );
 /// ditto

alias PyUnicodeUCS2_TranslateCharmap PyUnicode_TranslateCharmap;


    version (Windows) {
        /// Availability: Windows only
      PyObject* PyUnicodeUCS2_DecodeMBCS(
              const(char)* string,
              Py_ssize_t length,
              const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_DecodeMBCS PyUnicode_DecodeMBCS;

        /// Availability: Windows only
      PyObject* PyUnicodeUCS2_AsMBCSString(PyObject* unicode);
 /// ditto

alias PyUnicodeUCS2_AsMBCSString PyUnicode_AsMBCSString;

        /// Availability: Windows only
      PyObject* PyUnicodeUCS2_EncodeMBCS(
              Py_UNICODE* data,
              Py_ssize_t length,
              const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_EncodeMBCS PyUnicode_EncodeMBCS;

    }
    /** Takes a Unicode string holding a decimal value and writes it into
      an output buffer using standard ASCII digit codes.

      The output buffer has to provide at least length+1 bytes of storage
      area. The output string is 0-terminated.

      The encoder converts whitespace to ' ', decimal characters to their
      corresponding ASCII digit and all other Latin-1 characters except
      \0 as-is. Characters outside this range (Unicode ordinals 1-256)
      are treated as errors. This includes embedded NULL bytes.

      Error handling is defined by the errors argument:

      NULL or "strict": raise a ValueError
      "ignore": ignore the wrong characters (these are not copied to the
      output buffer)
      "replace": replaces illegal characters with '?'

      Returns 0 on success, -1 on failure.

     */
    int PyUnicodeUCS2_EncodeDecimal(
            Py_UNICODE* s,
            Py_ssize_t length,
            char* output,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_EncodeDecimal PyUnicode_EncodeDecimal;


    /** Concat two strings giving a new Unicode string. */
    PyObject* PyUnicodeUCS2_Concat(
            PyObject* left,
            PyObject* right);
 /// ditto

alias PyUnicodeUCS2_Concat PyUnicode_Concat;


    version(Python_3_0_Or_Later) {
        /** Concat two strings and put the result in *pleft
           (sets *pleft to NULL on error)
Params:
pleft = Pointer to left string
right = Right string
         */
        /// Availability: 3.*

        void PyUnicodeUCS2_Append(
                PyObject** pleft,
                PyObject* right
                );
 /// ditto

alias PyUnicodeUCS2_Append PyUnicode_Append;


        /** Concat two strings, put the result in *pleft and drop the right object
           (sets *pleft to NULL on error)
Params:
pleft = Pointer to left string
         */
        /// Availability: 3.*
        void PyUnicodeUCS2_AppendAndDel(
                PyObject** pleft,
                PyObject* right
                );
 /// ditto

alias PyUnicodeUCS2_AppendAndDel PyUnicode_AppendAndDel;

    }

    /** Split a string giving a list of Unicode strings.

      If sep is NULL, splitting will be done at all whitespace
      substrings. Otherwise, splits occur at the given separator.

      At most maxsplit splits will be done. If negative, no limit is set.

      Separators are not included in the resulting list.

     */
    PyObject* PyUnicodeUCS2_Split(
            PyObject* s,
            PyObject* sep,
            Py_ssize_t maxsplit);
 /// ditto

alias PyUnicodeUCS2_Split PyUnicode_Split;


    /** Ditto PyUnicode_Split, but split at line breaks.

       CRLF is considered to be one line break. Line breaks are not
       included in the resulting list. */
    PyObject* PyUnicodeUCS2_Splitlines(
            PyObject* s,
            int keepends);
 /// ditto

alias PyUnicodeUCS2_Splitlines PyUnicode_Splitlines;


    version(Python_2_5_Or_Later) {
        /** Partition a string using a given separator. */
        /// Availability: >= 2.5
        PyObject* PyUnicodeUCS2_Partition(
                PyObject* s,
                PyObject* sep
                );
 /// ditto

alias PyUnicodeUCS2_Partition PyUnicode_Partition;


        /** Partition a string using a given separator, searching from the end
          of the string. */

        PyObject* PyUnicodeUCS2_RPartition(
                PyObject* s,
                PyObject* sep
                );
 /// ditto

alias PyUnicodeUCS2_RPartition PyUnicode_RPartition;

    }

    /** Split a string giving a list of Unicode strings.

       If sep is NULL, splitting will be done at all whitespace
       substrings. Otherwise, splits occur at the given separator.

       At most maxsplit splits will be done. But unlike PyUnicode_Split
       PyUnicode_RSplit splits from the end of the string. If negative,
       no limit is set.

       Separators are not included in the resulting list.

     */
    PyObject* PyUnicodeUCS2_RSplit(
            PyObject* s,
            PyObject* sep,
            Py_ssize_t maxsplit);
 /// ditto

alias PyUnicodeUCS2_RSplit PyUnicode_RSplit;


    /** Translate a string by applying a character mapping table to it and
      return the resulting Unicode object.

      The mapping table must map Unicode ordinal integers to Unicode
      ordinal integers or None (causing deletion of the character).

      Mapping tables may be dictionaries or sequences. Unmapped character
      ordinals (ones which cause a LookupError) are left untouched and
      are copied as-is.

     */
    PyObject* PyUnicodeUCS2_Translate(
            PyObject* str,
            PyObject* table,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS2_Translate PyUnicode_Translate;


    /** Join a sequence of strings using the given separator and return
      the resulting Unicode string. */
    PyObject* PyUnicodeUCS2_Join(
            PyObject* separator,
            PyObject* seq);
 /// ditto

alias PyUnicodeUCS2_Join PyUnicode_Join;


    /** Return 1 if substr matches str[start:end] at the given tail end, 0
      otherwise. */
    Py_ssize_t PyUnicodeUCS2_Tailmatch(
            PyObject* str,
            PyObject* substr,
            Py_ssize_t start,
            Py_ssize_t end,
            int direction
      );
 /// ditto

alias PyUnicodeUCS2_Tailmatch PyUnicode_Tailmatch;


    /** Return the first position of substr in str[start:end] using the
      given search direction or -1 if not found. -2 is returned in case
      an error occurred and an exception is set. */
    Py_ssize_t PyUnicodeUCS2_Find(
            PyObject* str,
            PyObject* substr,
            Py_ssize_t start,
            Py_ssize_t end,
            int direction
      );
 /// ditto

alias PyUnicodeUCS2_Find PyUnicode_Find;


    /** Count the number of occurrences of substr in str[start:end]. */
    Py_ssize_t PyUnicodeUCS2_Count(
            PyObject* str,
            PyObject* substr,
            Py_ssize_t start,
            Py_ssize_t end);
 /// ditto

alias PyUnicodeUCS2_Count PyUnicode_Count;


    /** Replace at most maxcount occurrences of substr in str with replstr
       and return the resulting Unicode object. */
    PyObject* PyUnicodeUCS2_Replace(
            PyObject* str,
            PyObject* substr,
            PyObject* replstr,
            Py_ssize_t maxcount
      );
 /// ditto

alias PyUnicodeUCS2_Replace PyUnicode_Replace;


    /** Compare two strings and return -1, 0, 1 for less than, equal,
      greater than resp. */
    int PyUnicodeUCS2_Compare(PyObject* left, PyObject* right);
 /// ditto

alias PyUnicodeUCS2_Compare PyUnicode_Compare;

    version(Python_3_0_Or_Later) {
        /** Compare two strings and return -1, 0, 1 for less than, equal,
          greater than resp.
Params:
left =
right = ASCII-encoded string
         */
        /// Availability: 3.*
        int PyUnicodeUCS2_CompareWithASCIIString(
                PyObject* left,
                const(char)* right
                );
 /// ditto

alias PyUnicodeUCS2_CompareWithASCIIString PyUnicode_CompareWithASCIIString;

    }

    version(Python_2_5_Or_Later) {
        /** Rich compare two strings and return one of the following:

          - NULL in case an exception was raised
          - Py_True or Py_False for successfuly comparisons
          - Py_NotImplemented in case the type combination is unknown

          Note that Py_EQ and Py_NE comparisons can cause a UnicodeWarning in
          case the conversion of the arguments to Unicode fails with a
          UnicodeDecodeError.

          Possible values for op:

          Py_GT, Py_GE, Py_EQ, Py_NE, Py_LT, Py_LE

         */
        /// Availability: >= 2.5
        PyObject* PyUnicodeUCS2_RichCompare(
                PyObject* left,
                PyObject* right,
                int op
                );
 /// ditto

alias PyUnicodeUCS2_RichCompare PyUnicode_RichCompare;

    }

    /** Apply a argument tuple or dictionary to a format string and return
      the resulting Unicode string. */
    PyObject* PyUnicodeUCS2_Format(PyObject* format, PyObject* args);
 /// ditto

alias PyUnicodeUCS2_Format PyUnicode_Format;


    /** Checks whether element is contained in container and return 1/0
       accordingly.

       element has to coerce to an one element Unicode string. -1 is
       returned in case of an error. */
    int PyUnicodeUCS2_Contains(PyObject* container, PyObject* element);
 /// ditto

alias PyUnicodeUCS2_Contains PyUnicode_Contains;


    version(Python_3_0_Or_Later) {
        /** Checks whether argument is a valid identifier. */
        /// Availability: 3.*
        int PyUnicodeUCS2_IsIdentifier(PyObject* s);
 /// ditto

alias PyUnicodeUCS2_IsIdentifier PyUnicode_IsIdentifier;

    }


    /// _
    int _PyUnicodeUCS2_IsLowercase(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS2_IsLowercase _PyUnicode_IsLowercase;

    /// _
    int _PyUnicodeUCS2_IsUppercase(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS2_IsUppercase _PyUnicode_IsUppercase;

    /// _
    int _PyUnicodeUCS2_IsTitlecase(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS2_IsTitlecase _PyUnicode_IsTitlecase;

    /// _
    int _PyUnicodeUCS2_IsWhitespace(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS2_IsWhitespace _PyUnicode_IsWhitespace;

    /// _
    int _PyUnicodeUCS2_IsLinebreak(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS2_IsLinebreak _PyUnicode_IsLinebreak;

    /// _
    Py_UNICODE _PyUnicodeUCS2_ToLowercase(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS2_ToLowercase _PyUnicode_ToLowercase;

    /// _
    Py_UNICODE _PyUnicodeUCS2_ToUppercase(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS2_ToUppercase _PyUnicode_ToUppercase;

    /// _
    Py_UNICODE _PyUnicodeUCS2_ToTitlecase(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS2_ToTitlecase _PyUnicode_ToTitlecase;

    /// _
    int _PyUnicodeUCS2_ToDecimalDigit(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS2_ToDecimalDigit _PyUnicode_ToDecimalDigit;

    /// _
    int _PyUnicodeUCS2_ToDigit(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS2_ToDigit _PyUnicode_ToDigit;

    /// _
    double _PyUnicodeUCS2_ToNumeric(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS2_ToNumeric _PyUnicode_ToNumeric;

    /// _
    int _PyUnicodeUCS2_IsDecimalDigit(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS2_IsDecimalDigit _PyUnicode_IsDecimalDigit;

    /// _
    int _PyUnicodeUCS2_IsDigit(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS2_IsDigit _PyUnicode_IsDigit;

    /// _
    int _PyUnicodeUCS2_IsNumeric(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS2_IsNumeric _PyUnicode_IsNumeric;

    /// _
    int _PyUnicodeUCS2_IsAlpha(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS2_IsAlpha _PyUnicode_IsAlpha;

}else{

    version(Python_2_6_Or_Later) {

    /** Create a Unicode Object from the Py_UNICODE buffer u of the given
       size.

       u may be NULL which causes the contents to be undefined. It is the
       user's responsibility to fill in the needed data afterwards. Note
       that modifying the Unicode object contents after construction is
       only allowed if u was set to NULL.

       The buffer is copied into the new object. */
        /// Availability: >= 2.6
        PyObject* PyUnicodeUCS4_FromUnicode(Py_UNICODE* u, Py_ssize_t size);
 /// ditto

alias PyUnicodeUCS4_FromUnicode PyUnicode_FromUnicode;


      /** Similar to PyUnicode_FromUnicode(), but u points to Latin-1 encoded bytes */
        /// Availability: >= 2.6
      PyObject* PyUnicodeUCS4_FromStringAndSize(
              const(char)*u,        /* char buffer */
              Py_ssize_t size       /* size of buffer */
              );
 /// ditto

alias PyUnicodeUCS4_FromStringAndSize PyUnicode_FromStringAndSize;


      /** Similar to PyUnicode_FromUnicode(), but u points to null-terminated
         Latin-1 encoded bytes */
        /// Availability: >= 2.6
      PyObject* PyUnicodeUCS4_FromString(
              const(char)*u        /* string */
              );
 /// ditto

alias PyUnicodeUCS4_FromString PyUnicode_FromString;

        /// Availability: >= 2.6
      PyObject* PyUnicodeUCS4_FromFormatV(const(char)*, va_list);
 /// ditto

alias PyUnicodeUCS4_FromFormatV PyUnicode_FromFormatV;

        /// Availability: >= 2.6
      PyObject* PyUnicodeUCS4_FromFormat(const(char)*, ...);
 /// ditto

alias PyUnicodeUCS4_FromFormat PyUnicode_FromFormat;


      /** Format the object based on the format_spec, as defined in PEP 3101
         (Advanced String Formatting). */
        /// Availability: >= 2.6
      PyObject* _PyUnicodeUCS4_FormatAdvanced(PyObject *obj,
              Py_UNICODE *format_spec,
              Py_ssize_t format_spec_len);
 /// ditto

alias _PyUnicodeUCS4_FormatAdvanced _PyUnicode_FormatAdvanced;

        /// Availability: >= 2.6
      int PyUnicodeUCS4_ClearFreeList();
 /// ditto

alias PyUnicodeUCS4_ClearFreeList PyUnicode_ClearFreeList;

      /**
Params:
string = UTF-7 encoded string
length = size of string
error = error handling
consumed = bytes consumed
*/
        /// Availability: >= 2.6
      PyObject* PyUnicodeUCS4_DecodeUTF7Stateful(
              const(char)* string,
              Py_ssize_t length,
              const(char)*errors,
              Py_ssize_t *consumed
              );
 /// ditto

alias PyUnicodeUCS4_DecodeUTF7Stateful PyUnicode_DecodeUTF7Stateful;

      /**
Params:
string = UTF-32 encoded string
length = size of string
error = error handling
byteorder = pointer to byteorder to use 0=native;-1=LE,1=BE; updated on exit
*/
        /// Availability: >= 2.6
      PyObject* PyUnicodeUCS4_DecodeUTF32(
              const(char)* string,
              Py_ssize_t length,
              const(char)*errors,
              int *byteorder
              );
 /// ditto

alias PyUnicodeUCS4_DecodeUTF32 PyUnicode_DecodeUTF32;


      /**
Params:
string = UTF-32 encoded string
length = size of string
error = error handling
byteorder = pointer to byteorder to use 0=native;-1=LE,1=BE; updated on exit
*/
        /// Availability: >= 2.6
      PyObject* PyUnicodeUCS4_DecodeUTF32Stateful(
              const(char)*string,
              Py_ssize_t length,
              const(char)*errors,
              int *byteorder,
              Py_ssize_t *consumed
              );
 /// ditto

alias PyUnicodeUCS4_DecodeUTF32Stateful PyUnicode_DecodeUTF32Stateful;

      /** Returns a Python string using the UTF-32 encoding in native byte
         order. The string always starts with a BOM mark.  */
        /// Availability: >= 2.6

      PyObject* PyUnicodeUCS4_AsUTF32String(
              PyObject *unicode
              );
 /// ditto

alias PyUnicodeUCS4_AsUTF32String PyUnicode_AsUTF32String;


      /** Returns a Python string object holding the UTF-32 encoded value of
         the Unicode data.

         If byteorder is not 0, output is written according to the following
         byte order:

         byteorder == -1: little endian
         byteorder == 0:  native byte order (writes a BOM mark)
         byteorder == 1:  big endian

         If byteorder is 0, the output string will always start with the
         Unicode BOM mark (U+FEFF). In the other two modes, no BOM mark is
         prepended.
Params:
data = Unicode char buffer
length = number of Py_UNICODE chars to encode
errors = error handling
byteorder = byteorder to use 0=BOM+native;-1=LE,1=BE

       */
        /// Availability: >= 2.6
      PyObject* PyUnicodeUCS4_EncodeUTF32(
              const Py_UNICODE *data,
              Py_ssize_t length,
              const(char)* errors,
              int byteorder
              );
 /// ditto

alias PyUnicodeUCS4_EncodeUTF32 PyUnicode_EncodeUTF32;

      }

    /** Return a read-only pointer to the Unicode object's internal
      Py_UNICODE buffer. */
    Py_UNICODE* PyUnicodeUCS4_AsUnicode(PyObject* unicode);
 /// ditto

alias PyUnicodeUCS4_AsUnicode PyUnicode_AsUnicode;

    /** Get the length of the Unicode object. */
    Py_ssize_t PyUnicodeUCS4_GetSize(PyObject* unicode);
 /// ditto

alias PyUnicodeUCS4_GetSize PyUnicode_GetSize;


    /** Get the maximum ordinal for a Unicode character. */
    Py_UNICODE PyUnicodeUCS4_GetMax();
 /// ditto

alias PyUnicodeUCS4_GetMax PyUnicode_GetMax;


    /** Resize an already allocated Unicode object to the new size length.

   _*unicode is modified to point to the new (resized) object and 0
   returned on success.

   This API may only be called by the function which also called the
   Unicode constructor. The refcount on the object must be 1. Otherwise,
   an error is returned.

   Error handling is implemented as follows: an exception is set, -1
   is returned and *unicode left untouched.
Params:
unicode = pointer to the new unicode object.
length = New length.

*/
    int PyUnicodeUCS4_Resize(PyObject** unicode, Py_ssize_t length);
 /// ditto

alias PyUnicodeUCS4_Resize PyUnicode_Resize;

    /** Coerce obj to an Unicode object and return a reference with
     _*incremented* refcount.

     Coercion is done in the following way:

     1. String and other char buffer compatible objects are decoded
     under the assumptions that they contain data using the current
     default encoding. Decoding is done in "strict" mode.

     2. All other objects (including Unicode objects) raise an
     exception.

     The API returns NULL in case of an error. The caller is responsible
     for decref'ing the returned objects.

     */
    PyObject* PyUnicodeUCS4_FromEncodedObject(
            PyObject* obj,
            const(char)* encoding,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_FromEncodedObject PyUnicode_FromEncodedObject;


    /** Coerce obj to an Unicode object and return a reference with
     _*incremented* refcount.

     Unicode objects are passed back as-is (subclasses are converted to
     true Unicode objects), all other objects are delegated to
     PyUnicode_FromEncodedObject(obj, NULL, "strict") which results in
     using the default encoding as basis for decoding the object.

     The API returns NULL in case of an error. The caller is responsible
     for decref'ing the returned objects.

     */
    PyObject* PyUnicodeUCS4_FromObject(PyObject* obj);
 /// ditto

alias PyUnicodeUCS4_FromObject PyUnicode_FromObject;


    /** Create a Unicode Object from the whcar_t buffer w of the given
      size.

      The buffer is copied into the new object. */
    PyObject* PyUnicodeUCS4_FromWideChar(const(wchar_t)* w, Py_ssize_t size);
 /// ditto

alias PyUnicodeUCS4_FromWideChar PyUnicode_FromWideChar;


    /** Copies the Unicode Object contents into the wchar_t buffer w.  At
      most size wchar_t characters are copied.

      Note that the resulting wchar_t string may or may not be
      0-terminated.  It is the responsibility of the caller to make sure
      that the wchar_t string is 0-terminated in case this is required by
      the application.

      Returns the number of wchar_t characters copied (excluding a
      possibly trailing 0-termination character) or -1 in case of an
      error. */
    Py_ssize_t PyUnicodeUCS4_AsWideChar(
            PyUnicodeObject* unicode,
            const(wchar_t)* w,
            Py_ssize_t size);
 /// ditto

alias PyUnicodeUCS4_AsWideChar PyUnicode_AsWideChar;


    /** Create a Unicode Object from the given Unicode code point ordinal.

       The ordinal must be in range(0x10000) on narrow Python builds
       (UCS2), and range(0x110000) on wide builds (UCS4). A ValueError is
       raised in case it is not.

     */
    PyObject* PyUnicodeUCS4_FromOrdinal(int ordinal);
 /// ditto

alias PyUnicodeUCS4_FromOrdinal PyUnicode_FromOrdinal;


    /** Return a Python string holding the default encoded value of the
      Unicode object.

      The resulting string is cached in the Unicode object for subsequent
      usage by this function. The cached version is needed to implement
      the character buffer interface and will live (at least) as long as
      the Unicode object itself.

      The refcount of the string is *not* incremented.

     _*** Exported for internal use by the interpreter only !!! ***

     */
    PyObject* _PyUnicodeUCS4_AsDefaultEncodedString(PyObject *, const(char)*);
 /// ditto

alias _PyUnicodeUCS4_AsDefaultEncodedString _PyUnicode_AsDefaultEncodedString;


    /** Returns the currently active default encoding.

      The default encoding is currently implemented as run-time settable
      process global.  This may change in future versions of the
      interpreter to become a parameter which is managed on a per-thread
      basis.

     */
    const(char)* PyUnicodeUCS4_GetDefaultEncoding();
 /// ditto

alias PyUnicodeUCS4_GetDefaultEncoding PyUnicode_GetDefaultEncoding;


    /** Sets the currently active default encoding.

       Returns 0 on success, -1 in case of an error.

     */
    int PyUnicodeUCS4_SetDefaultEncoding(const(char)*encoding);
 /// ditto

alias PyUnicodeUCS4_SetDefaultEncoding PyUnicode_SetDefaultEncoding;


    /** Create a Unicode object by decoding the encoded string s of the
      given size.
Params:
s = encoded string
size = size of buffer
encoding = encoding
errors = error handling
     */
    PyObject* PyUnicodeUCS4_Decode(
            const(char)* s,
            Py_ssize_t size,
            const(char)* encoding,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_Decode PyUnicode_Decode;


    version(Python_3_0_Or_Later) {
    /** Decode a Unicode object unicode and return the result as Python
      object. */
        /// Availability: 3.*

    PyObject* PyUnicodeUCS4_AsDecodedObject(
            PyObject* unicode,
            const(char)* encoding,
            const(char)* errors
            );
 /// ditto

alias PyUnicodeUCS4_AsDecodedObject PyUnicode_AsDecodedObject;

    /** Decode a Unicode object unicode and return the result as Unicode
      object. */
        /// Availability: 3.*

    PyObject* PyUnicodeUCS4_AsDecodedUnicode(
            PyObject* unicode,
            const(char)* encoding,
            const(char)* errors
            );
 /// ditto

alias PyUnicodeUCS4_AsDecodedUnicode PyUnicode_AsDecodedUnicode;

    }

    /** Encodes a Py_UNICODE buffer of the given size and returns a
      Python string object.
Params:
s = Unicode char buffer
size = number of Py_UNICODE chars to encode
encoding = encoding
errors = error handling
     */
    PyObject* PyUnicodeUCS4_Encode(
            Py_UNICODE* s,
            Py_ssize_t size,
            const(char)* encoding,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_Encode PyUnicode_Encode;


    /** Encodes a Unicode object and returns the result as Python object.
     */
    PyObject* PyUnicodeUCS4_AsEncodedObject(
            PyObject* unicode,
            const(char)* encoding,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_AsEncodedObject PyUnicode_AsEncodedObject;


    /** Encodes a Unicode object and returns the result as Python string
      object. */
    PyObject* PyUnicodeUCS4_AsEncodedString(
            PyObject* unicode,
            const(char)* encoding,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_AsEncodedString PyUnicode_AsEncodedString;


    version(Python_3_0_Or_Later) {
        /** Encodes a Unicode object and returns the result as Unicode
           object. */
        /// Availability: >= 3.*
        PyObject* PyUnicodeUCS4_AsEncodedUnicode(
                PyObject* unicode,
                const(char)* encoding,
                const(char)* errors
                );
 /// ditto

alias PyUnicodeUCS4_AsEncodedUnicode PyUnicode_AsEncodedUnicode;

    }

    /**
Params:
    string = UTF-7 encoded string
    length = size of string
    errors = error handling
    */
    PyObject* PyUnicodeUCS4_DecodeUTF7(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_DecodeUTF7 PyUnicode_DecodeUTF7;


    /**
Params:
    data = Unicode char buffer
    length = number of Py_UNICODE chars to encode
    base64SetO = Encode RFC2152 Set O characters in base64
    base64WhiteSpace = Encode whitespace (sp, ht, nl, cr) in base64
    errors = error handling
    */
    PyObject* PyUnicodeUCS4_EncodeUTF7(
            Py_UNICODE* data,
            Py_ssize_t length,
            int encodeSetO,
            int encodeWhiteSpace,
            const(char)* errors
      );
 /// ditto

alias PyUnicodeUCS4_EncodeUTF7 PyUnicode_EncodeUTF7;


    /// _
    PyObject* PyUnicodeUCS4_DecodeUTF8(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_DecodeUTF8 PyUnicode_DecodeUTF8;

    /// _
    PyObject* PyUnicodeUCS4_DecodeUTF8Stateful(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors,
            Py_ssize_t* consumed
      );
 /// ditto

alias PyUnicodeUCS4_DecodeUTF8Stateful PyUnicode_DecodeUTF8Stateful;

    /// _
    PyObject* PyUnicodeUCS4_AsUTF8String(PyObject* unicode);
 /// ditto

alias PyUnicodeUCS4_AsUTF8String PyUnicode_AsUTF8String;

    /// _
    PyObject* PyUnicodeUCS4_EncodeUTF8(
            Py_UNICODE* data,
            Py_ssize_t length,
            const(char) *errors);
 /// ditto

alias PyUnicodeUCS4_EncodeUTF8 PyUnicode_EncodeUTF8;


    /** Decodes length bytes from a UTF-16 encoded buffer string and returns
      the corresponding Unicode object.

      errors (if non-NULL) defines the error handling. It defaults
      to "strict".

      If byteorder is non-NULL, the decoder starts decoding using the
      given byte order:

     *byteorder == -1: little endian
     *byteorder == 0:  native order
     *byteorder == 1:  big endian

     In native mode, the first two bytes of the stream are checked for a
     BOM mark. If found, the BOM mark is analysed, the byte order
     adjusted and the BOM skipped.  In the other modes, no BOM mark
     interpretation is done. After completion, *byteorder is set to the
     current byte order at the end of input data.

     If byteorder is NULL, the codec starts in native order mode.

     */
    PyObject* PyUnicodeUCS4_DecodeUTF16(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors,
            int* byteorder);
 /// ditto

alias PyUnicodeUCS4_DecodeUTF16 PyUnicode_DecodeUTF16;

    /**
Params:
string = UTF-16 encoded string
length = size of string
errors = error handling
byteorder = pointer to byteorder to use 0=native;-1=LE,1=BE; updated on exit
consumed = bytes consumed
        */
    PyObject* PyUnicodeUCS4_DecodeUTF16Stateful(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors,
            int* byteorder,
            Py_ssize_t* consumed
      );
 /// ditto

alias PyUnicodeUCS4_DecodeUTF16Stateful PyUnicode_DecodeUTF16Stateful;

    /** Returns a Python string using the UTF-16 encoding in native byte
       order. The string always starts with a BOM mark.  */
    PyObject* PyUnicodeUCS4_AsUTF16String(PyObject *unicode);
 /// ditto

alias PyUnicodeUCS4_AsUTF16String PyUnicode_AsUTF16String;

    /** Returns a Python string object holding the UTF-16 encoded value of
       the Unicode data.

       If byteorder is not 0, output is written according to the following
       byte order:

       byteorder == -1: little endian
       byteorder == 0:  native byte order (writes a BOM mark)
       byteorder == 1:  big endian

       If byteorder is 0, the output string will always start with the
       Unicode BOM mark (U+FEFF). In the other two modes, no BOM mark is
       prepended.

       Note that Py_UNICODE data is being interpreted as UTF-16 reduced to
       UCS-2. This trick makes it possible to add full UTF-16 capabilities
       at a later point without compromising the APIs.

     */
    PyObject* PyUnicodeUCS4_EncodeUTF16(
            Py_UNICODE* data,
            Py_ssize_t length,
            const(char)* errors,
            int byteorder
      );
 /// ditto

alias PyUnicodeUCS4_EncodeUTF16 PyUnicode_EncodeUTF16;


    /// _
    PyObject* PyUnicodeUCS4_DecodeUnicodeEscape(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_DecodeUnicodeEscape PyUnicode_DecodeUnicodeEscape;

    /// _
    PyObject* PyUnicodeUCS4_AsUnicodeEscapeString(
            PyObject* unicode);
 /// ditto

alias PyUnicodeUCS4_AsUnicodeEscapeString PyUnicode_AsUnicodeEscapeString;

    /// _
    PyObject* PyUnicodeUCS4_EncodeUnicodeEscape(
            Py_UNICODE* data,
            Py_ssize_t length);
 /// ditto

alias PyUnicodeUCS4_EncodeUnicodeEscape PyUnicode_EncodeUnicodeEscape;

    /**
Params:
string = Raw-Unicode-Escape encoded string
length = size of string
errors = error handling
    */
    PyObject* PyUnicodeUCS4_DecodeRawUnicodeEscape(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_DecodeRawUnicodeEscape PyUnicode_DecodeRawUnicodeEscape;

    /// _
    PyObject* PyUnicodeUCS4_AsRawUnicodeEscapeString(PyObject* unicode);
 /// ditto

alias PyUnicodeUCS4_AsRawUnicodeEscapeString PyUnicode_AsRawUnicodeEscapeString;

    /// _
    PyObject* PyUnicodeUCS4_EncodeRawUnicodeEscape(
            Py_UNICODE* data, Py_ssize_t length);
 /// ditto

alias PyUnicodeUCS4_EncodeRawUnicodeEscape PyUnicode_EncodeRawUnicodeEscape;


    /// _
    PyObject* _PyUnicodeUCS4_DecodeUnicodeInternal(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias _PyUnicodeUCS4_DecodeUnicodeInternal _PyUnicode_DecodeUnicodeInternal;


    /**
Params:
string = Latin-1 encoded string
length = size of string
errors = error handling
     */
    PyObject* PyUnicodeUCS4_DecodeLatin1(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_DecodeLatin1 PyUnicode_DecodeLatin1;

    /// _
    PyObject* PyUnicodeUCS4_AsLatin1String(PyObject *unicode);
 /// ditto

alias PyUnicodeUCS4_AsLatin1String PyUnicode_AsLatin1String;

    /**
Params:
data = Unicode char buffer
length = Number of Py_UNICODE chars to encode
errors = error handling
    */
    PyObject* PyUnicodeUCS4_EncodeLatin1(
            Py_UNICODE* data,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_EncodeLatin1 PyUnicode_EncodeLatin1;


    /**
Params:
    data = Unicode char buffer
    length = Number of Py_UNICODE chars to encode
    errors = error handling
    */
    PyObject* PyUnicodeUCS4_DecodeASCII(
            const(char)* string,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_DecodeASCII PyUnicode_DecodeASCII;

    /// _
    PyObject* PyUnicodeUCS4_AsASCIIString(PyObject *unicode);
 /// ditto

alias PyUnicodeUCS4_AsASCIIString PyUnicode_AsASCIIString;

    /**
Params:
    data = Unicode char buffer
    length = Number of Py_UNICODE chars to encode
    errors = error handling
      */
    PyObject* PyUnicodeUCS4_EncodeASCII(
            Py_UNICODE* data,
            Py_ssize_t length,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_EncodeASCII PyUnicode_EncodeASCII;


    /**
Params:
    string = Encoded string
    length = size of string
    mapping = character mapping (char ordinal -> unicode ordinal)
    errors = error handling
      */
    PyObject* PyUnicodeUCS4_DecodeCharmap(
            const(char)* string,
            Py_ssize_t length,
            PyObject* mapping,
            const(char)* errors
      );
 /// ditto

alias PyUnicodeUCS4_DecodeCharmap PyUnicode_DecodeCharmap;

    /**
Params:
    unicode = Unicode object
    mapping = character mapping (unicode ordinal -> char ordinal)
      */
    PyObject* PyUnicodeUCS4_AsCharmapString(
            PyObject* unicode,
            PyObject* mapping);
 /// ditto

alias PyUnicodeUCS4_AsCharmapString PyUnicode_AsCharmapString;

    /**
Params:
    data = Unicode char buffer
    length = Number of Py_UNICODE chars to encode
    mapping = character mapping (unicode ordinal -> char ordinal)
    errors = error handling
      */
    PyObject* PyUnicodeUCS4_EncodeCharmap(
            Py_UNICODE* data,
            Py_ssize_t length,
            PyObject* mapping,
            const(char)* errors
      );
 /// ditto

alias PyUnicodeUCS4_EncodeCharmap PyUnicode_EncodeCharmap;

    /** Translate a Py_UNICODE buffer of the given length by applying a
      character mapping table to it and return the resulting Unicode
      object.

      The mapping table must map Unicode ordinal integers to Unicode
      ordinal integers or None (causing deletion of the character).

      Mapping tables may be dictionaries or sequences. Unmapped character
      ordinals (ones which cause a LookupError) are left untouched and
      are copied as-is.

     */
    PyObject* PyUnicodeUCS4_TranslateCharmap(
            Py_UNICODE* data,
            Py_ssize_t length,
            PyObject* table,
            const(char)* errors
      );
 /// ditto

alias PyUnicodeUCS4_TranslateCharmap PyUnicode_TranslateCharmap;


    version (Windows) {
        /// Availability: Windows only
      PyObject* PyUnicodeUCS4_DecodeMBCS(
              const(char)* string,
              Py_ssize_t length,
              const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_DecodeMBCS PyUnicode_DecodeMBCS;

        /// Availability: Windows only
      PyObject* PyUnicodeUCS4_AsMBCSString(PyObject* unicode);
 /// ditto

alias PyUnicodeUCS4_AsMBCSString PyUnicode_AsMBCSString;

        /// Availability: Windows only
      PyObject* PyUnicodeUCS4_EncodeMBCS(
              Py_UNICODE* data,
              Py_ssize_t length,
              const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_EncodeMBCS PyUnicode_EncodeMBCS;

    }
    /** Takes a Unicode string holding a decimal value and writes it into
      an output buffer using standard ASCII digit codes.

      The output buffer has to provide at least length+1 bytes of storage
      area. The output string is 0-terminated.

      The encoder converts whitespace to ' ', decimal characters to their
      corresponding ASCII digit and all other Latin-1 characters except
      \0 as-is. Characters outside this range (Unicode ordinals 1-256)
      are treated as errors. This includes embedded NULL bytes.

      Error handling is defined by the errors argument:

      NULL or "strict": raise a ValueError
      "ignore": ignore the wrong characters (these are not copied to the
      output buffer)
      "replace": replaces illegal characters with '?'

      Returns 0 on success, -1 on failure.

     */
    int PyUnicodeUCS4_EncodeDecimal(
            Py_UNICODE* s,
            Py_ssize_t length,
            char* output,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_EncodeDecimal PyUnicode_EncodeDecimal;


    /** Concat two strings giving a new Unicode string. */
    PyObject* PyUnicodeUCS4_Concat(
            PyObject* left,
            PyObject* right);
 /// ditto

alias PyUnicodeUCS4_Concat PyUnicode_Concat;


    version(Python_3_0_Or_Later) {
        /** Concat two strings and put the result in *pleft
           (sets *pleft to NULL on error)
Params:
pleft = Pointer to left string
right = Right string
         */
        /// Availability: 3.*

        void PyUnicodeUCS4_Append(
                PyObject** pleft,
                PyObject* right
                );
 /// ditto

alias PyUnicodeUCS4_Append PyUnicode_Append;


        /** Concat two strings, put the result in *pleft and drop the right object
           (sets *pleft to NULL on error)
Params:
pleft = Pointer to left string
         */
        /// Availability: 3.*
        void PyUnicodeUCS4_AppendAndDel(
                PyObject** pleft,
                PyObject* right
                );
 /// ditto

alias PyUnicodeUCS4_AppendAndDel PyUnicode_AppendAndDel;

    }

    /** Split a string giving a list of Unicode strings.

      If sep is NULL, splitting will be done at all whitespace
      substrings. Otherwise, splits occur at the given separator.

      At most maxsplit splits will be done. If negative, no limit is set.

      Separators are not included in the resulting list.

     */
    PyObject* PyUnicodeUCS4_Split(
            PyObject* s,
            PyObject* sep,
            Py_ssize_t maxsplit);
 /// ditto

alias PyUnicodeUCS4_Split PyUnicode_Split;


    /** Ditto PyUnicode_Split, but split at line breaks.

       CRLF is considered to be one line break. Line breaks are not
       included in the resulting list. */
    PyObject* PyUnicodeUCS4_Splitlines(
            PyObject* s,
            int keepends);
 /// ditto

alias PyUnicodeUCS4_Splitlines PyUnicode_Splitlines;


    version(Python_2_5_Or_Later) {
        /** Partition a string using a given separator. */
        /// Availability: >= 2.5
        PyObject* PyUnicodeUCS4_Partition(
                PyObject* s,
                PyObject* sep
                );
 /// ditto

alias PyUnicodeUCS4_Partition PyUnicode_Partition;


        /** Partition a string using a given separator, searching from the end
          of the string. */

        PyObject* PyUnicodeUCS4_RPartition(
                PyObject* s,
                PyObject* sep
                );
 /// ditto

alias PyUnicodeUCS4_RPartition PyUnicode_RPartition;

    }

    /** Split a string giving a list of Unicode strings.

       If sep is NULL, splitting will be done at all whitespace
       substrings. Otherwise, splits occur at the given separator.

       At most maxsplit splits will be done. But unlike PyUnicode_Split
       PyUnicode_RSplit splits from the end of the string. If negative,
       no limit is set.

       Separators are not included in the resulting list.

     */
    PyObject* PyUnicodeUCS4_RSplit(
            PyObject* s,
            PyObject* sep,
            Py_ssize_t maxsplit);
 /// ditto

alias PyUnicodeUCS4_RSplit PyUnicode_RSplit;


    /** Translate a string by applying a character mapping table to it and
      return the resulting Unicode object.

      The mapping table must map Unicode ordinal integers to Unicode
      ordinal integers or None (causing deletion of the character).

      Mapping tables may be dictionaries or sequences. Unmapped character
      ordinals (ones which cause a LookupError) are left untouched and
      are copied as-is.

     */
    PyObject* PyUnicodeUCS4_Translate(
            PyObject* str,
            PyObject* table,
            const(char)* errors);
 /// ditto

alias PyUnicodeUCS4_Translate PyUnicode_Translate;


    /** Join a sequence of strings using the given separator and return
      the resulting Unicode string. */
    PyObject* PyUnicodeUCS4_Join(
            PyObject* separator,
            PyObject* seq);
 /// ditto

alias PyUnicodeUCS4_Join PyUnicode_Join;


    /** Return 1 if substr matches str[start:end] at the given tail end, 0
      otherwise. */
    Py_ssize_t PyUnicodeUCS4_Tailmatch(
            PyObject* str,
            PyObject* substr,
            Py_ssize_t start,
            Py_ssize_t end,
            int direction
      );
 /// ditto

alias PyUnicodeUCS4_Tailmatch PyUnicode_Tailmatch;


    /** Return the first position of substr in str[start:end] using the
      given search direction or -1 if not found. -2 is returned in case
      an error occurred and an exception is set. */
    Py_ssize_t PyUnicodeUCS4_Find(
            PyObject* str,
            PyObject* substr,
            Py_ssize_t start,
            Py_ssize_t end,
            int direction
      );
 /// ditto

alias PyUnicodeUCS4_Find PyUnicode_Find;


    /** Count the number of occurrences of substr in str[start:end]. */
    Py_ssize_t PyUnicodeUCS4_Count(
            PyObject* str,
            PyObject* substr,
            Py_ssize_t start,
            Py_ssize_t end);
 /// ditto

alias PyUnicodeUCS4_Count PyUnicode_Count;


    /** Replace at most maxcount occurrences of substr in str with replstr
       and return the resulting Unicode object. */
    PyObject* PyUnicodeUCS4_Replace(
            PyObject* str,
            PyObject* substr,
            PyObject* replstr,
            Py_ssize_t maxcount
      );
 /// ditto

alias PyUnicodeUCS4_Replace PyUnicode_Replace;


    /** Compare two strings and return -1, 0, 1 for less than, equal,
      greater than resp. */
    int PyUnicodeUCS4_Compare(PyObject* left, PyObject* right);
 /// ditto

alias PyUnicodeUCS4_Compare PyUnicode_Compare;

    version(Python_3_0_Or_Later) {
        /** Compare two strings and return -1, 0, 1 for less than, equal,
          greater than resp.
Params:
left =
right = ASCII-encoded string
         */
        /// Availability: 3.*
        int PyUnicodeUCS4_CompareWithASCIIString(
                PyObject* left,
                const(char)* right
                );
 /// ditto

alias PyUnicodeUCS4_CompareWithASCIIString PyUnicode_CompareWithASCIIString;

    }

    version(Python_2_5_Or_Later) {
        /** Rich compare two strings and return one of the following:

          - NULL in case an exception was raised
          - Py_True or Py_False for successfuly comparisons
          - Py_NotImplemented in case the type combination is unknown

          Note that Py_EQ and Py_NE comparisons can cause a UnicodeWarning in
          case the conversion of the arguments to Unicode fails with a
          UnicodeDecodeError.

          Possible values for op:

          Py_GT, Py_GE, Py_EQ, Py_NE, Py_LT, Py_LE

         */
        /// Availability: >= 2.5
        PyObject* PyUnicodeUCS4_RichCompare(
                PyObject* left,
                PyObject* right,
                int op
                );
 /// ditto

alias PyUnicodeUCS4_RichCompare PyUnicode_RichCompare;

    }

    /** Apply a argument tuple or dictionary to a format string and return
      the resulting Unicode string. */
    PyObject* PyUnicodeUCS4_Format(PyObject* format, PyObject* args);
 /// ditto

alias PyUnicodeUCS4_Format PyUnicode_Format;


    /** Checks whether element is contained in container and return 1/0
       accordingly.

       element has to coerce to an one element Unicode string. -1 is
       returned in case of an error. */
    int PyUnicodeUCS4_Contains(PyObject* container, PyObject* element);
 /// ditto

alias PyUnicodeUCS4_Contains PyUnicode_Contains;


    version(Python_3_0_Or_Later) {
        /** Checks whether argument is a valid identifier. */
        /// Availability: 3.*
        int PyUnicodeUCS4_IsIdentifier(PyObject* s);
 /// ditto

alias PyUnicodeUCS4_IsIdentifier PyUnicode_IsIdentifier;

    }


    /// _
    int _PyUnicodeUCS4_IsLowercase(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS4_IsLowercase _PyUnicode_IsLowercase;

    /// _
    int _PyUnicodeUCS4_IsUppercase(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS4_IsUppercase _PyUnicode_IsUppercase;

    /// _
    int _PyUnicodeUCS4_IsTitlecase(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS4_IsTitlecase _PyUnicode_IsTitlecase;

    /// _
    int _PyUnicodeUCS4_IsWhitespace(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS4_IsWhitespace _PyUnicode_IsWhitespace;

    /// _
    int _PyUnicodeUCS4_IsLinebreak(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS4_IsLinebreak _PyUnicode_IsLinebreak;

    /// _
    Py_UNICODE _PyUnicodeUCS4_ToLowercase(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS4_ToLowercase _PyUnicode_ToLowercase;

    /// _
    Py_UNICODE _PyUnicodeUCS4_ToUppercase(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS4_ToUppercase _PyUnicode_ToUppercase;

    /// _
    Py_UNICODE _PyUnicodeUCS4_ToTitlecase(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS4_ToTitlecase _PyUnicode_ToTitlecase;

    /// _
    int _PyUnicodeUCS4_ToDecimalDigit(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS4_ToDecimalDigit _PyUnicode_ToDecimalDigit;

    /// _
    int _PyUnicodeUCS4_ToDigit(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS4_ToDigit _PyUnicode_ToDigit;

    /// _
    double _PyUnicodeUCS4_ToNumeric(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS4_ToNumeric _PyUnicode_ToNumeric;

    /// _
    int _PyUnicodeUCS4_IsDecimalDigit(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS4_IsDecimalDigit _PyUnicode_IsDecimalDigit;

    /// _
    int _PyUnicodeUCS4_IsDigit(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS4_IsDigit _PyUnicode_IsDigit;

    /// _
    int _PyUnicodeUCS4_IsNumeric(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS4_IsNumeric _PyUnicode_IsNumeric;

    /// _
    int _PyUnicodeUCS4_IsAlpha(Py_UNICODE ch);
 /// ditto

alias _PyUnicodeUCS4_IsAlpha _PyUnicode_IsAlpha;

}
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    size_t Py_UNICODE_strlen(const(Py_UNICODE)* u);

    /// Availability: 3.*
    Py_UNICODE* Py_UNICODE_strcpy(Py_UNICODE* s1, const(Py_UNICODE)* s2);

    version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    Py_UNICODE* Py_UNICODE_strcat(Py_UNICODE* s1, const(Py_UNICODE)* s2);
    }

    /// Availability: 3.*
    Py_UNICODE* Py_UNICODE_strncpy(
            Py_UNICODE* s1,
            const(Py_UNICODE)* s2,
            size_t n);

    /// Availability: 3.*
    int Py_UNICODE_strcmp(
            const(Py_UNICODE)* s1,
            const(Py_UNICODE)* s2
            );

    version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    int Py_UNICODE_strncmp(
            const(Py_UNICODE)* s1,
            const(Py_UNICODE)* s2,
            size_t n
            );
    }

    /// Availability: 3.*
    Py_UNICODE* Py_UNICODE_strchr(
            const(Py_UNICODE)* s,
            Py_UNICODE c
            );

    version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    Py_UNICODE* Py_UNICODE_strrchr(
            const(Py_UNICODE)* s,
            Py_UNICODE c
            );
    }

    version(Python_3_5_Or_Later) {
        /// Availability: >= 3.5
        PyObject* _PyUnicode_FormatLong(PyObject*, int, int, int);
    }

    version(Python_3_2_Or_Later) {
    /** Create a copy of a unicode string ending with a nul character. Return NULL
       and raise a MemoryError exception on memory allocation failure, otherwise
       return a new allocated buffer (use PyMem_Free() to free the buffer). */
    /// Availability: >= 3.2

    Py_UNICODE* PyUnicode_AsUnicodeCopy(
            PyObject* unicode
            );
    }
}


/// _
int _PyUnicode_IsTitlecase(
    Py_UCS4 ch       /* Unicode character */
    );

/// _
int _PyUnicode_IsXidStart(
    Py_UCS4 ch       /* Unicode character */
    );
/** Externally visible for str.strip(unicode) */
PyObject* _PyUnicode_XStrip(PyUnicodeObject* self, int striptype,
        PyObject *sepobj
        );
version(Python_3_0_Or_Later) {
    version(Python_3_2_Or_Later) {
    /** Using the current locale, insert the thousands grouping
      into the string pointed to by buffer.  For the argument descriptions,
      see Objects/stringlib/localeutil.h */
    /// Availability: >= 3.2
    Py_ssize_t _PyUnicode_InsertThousandsGroupingLocale(
            Py_UNICODE* buffer,
            Py_ssize_t n_buffer,
            Py_UNICODE* digits,
            Py_ssize_t n_digits,
            Py_ssize_t min_width);
    }

    /** Using explicit passed-in values, insert the thousands grouping
      into the string pointed to by buffer.  For the argument descriptions,
      see Objects/stringlib/localeutil.h */
    /// Availability: 3.*
    Py_ssize_t _PyUnicode_InsertThousandsGrouping(
            Py_UNICODE* buffer,
            Py_ssize_t n_buffer,
            Py_UNICODE* digits,
            Py_ssize_t n_digits,
            Py_ssize_t min_width,
            const(char)* grouping,
            const(char)* thousands_sep);
}

version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    PyObject* PyUnicode_TransformDecimalToASCII(
            Py_UNICODE *s,              /* Unicode buffer */
            Py_ssize_t length           /* Number of Py_UNICODE chars to transform */
            );
    /* --- File system encoding ---------------------------------------------- */

    /** ParseTuple converter: encode str objects to bytes using
      PyUnicode_EncodeFSDefault(); bytes objects are output as-is. */
    /// Availability: >= 3.2
    int PyUnicode_FSConverter(PyObject*, void*);

    /** ParseTuple converter: decode bytes objects to unicode using
      PyUnicode_DecodeFSDefaultAndSize(); str objects are output as-is. */
    /// Availability: >= 3.2
    int PyUnicode_FSDecoder(PyObject*, void*);

    /** Decode a null-terminated string using Py_FileSystemDefaultEncoding
      and the "surrogateescape" error handler.

      If Py_FileSystemDefaultEncoding is not set, fall back to the locale
      encoding.

      Use PyUnicode_DecodeFSDefaultAndSize() if the string length is known.
     */
    /// Availability: >= 3.2
    PyObject* PyUnicode_DecodeFSDefault(
            const(char)* s               /* encoded string */
            );

    /** Decode a string using Py_FileSystemDefaultEncoding
      and the "surrogateescape" error handler.

      If Py_FileSystemDefaultEncoding is not set, fall back to the locale
      encoding.
     */
    /// Availability: >= 3.2
    PyObject* PyUnicode_DecodeFSDefaultAndSize(
            const(char)* s,               /* encoded string */
            Py_ssize_t size              /* size */
            );

    /** Encode a Unicode object to Py_FileSystemDefaultEncoding with the
       "surrogateescape" error handler, and return bytes.

       If Py_FileSystemDefaultEncoding is not set, fall back to the locale
       encoding.
     */
    /// Availability: >= 3.2
    PyObject* PyUnicode_EncodeFSDefault(
            PyObject* unicode
            );
}

/*
alias _PyUnicode_IsWhitespace Py_UNICODE_ISSPACE;
alias _PyUnicode_IsLowercase Py_UNICODE_ISLOWER;
alias _PyUnicode_IsUppercase Py_UNICODE_ISUPPER;
alias _PyUnicode_IsTitlecase Py_UNICODE_ISTITLE;
alias _PyUnicode_IsLinebreak Py_UNICODE_ISLINEBREAK;
alias _PyUnicode_ToLowercase Py_UNICODE_TOLOWER;
alias _PyUnicode_ToUppercase Py_UNICODE_TOUPPER;
alias _PyUnicode_ToTitlecase Py_UNICODE_TOTITLE;
alias _PyUnicode_IsDecimalDigit Py_UNICODE_ISDECIMAL;
alias _PyUnicode_IsDigit Py_UNICODE_ISDIGIT;
alias _PyUnicode_IsNumeric Py_UNICODE_ISNUMERIC;
alias _PyUnicode_ToDecimalDigit Py_UNICODE_TODECIMAL;
alias _PyUnicode_ToDigit Py_UNICODE_TODIGIT;
alias _PyUnicode_ToNumeric Py_UNICODE_TONUMERIC;
alias _PyUnicode_IsAlpha Py_UNICODE_ISALPHA;
*/

/// _
int Py_UNICODE_ISALNUM()(Py_UNICODE ch) {
    return (
            Py_UNICODE_ISALPHA(ch)
            || Py_UNICODE_ISDECIMAL(ch)
            || Py_UNICODE_ISDIGIT(ch)
            || Py_UNICODE_ISNUMERIC(ch)
           );
}

/// _
void Py_UNICODE_COPY()(void* target, void* source, size_t length) {
    memcpy(target, source, cast(uint)(length* Py_UNICODE.sizeof));
}

/// _
void Py_UNICODE_FILL()(Py_UNICODE* target, Py_UNICODE value, size_t length) {
    for (size_t i = 0; i < length; i++) {
        target[i] = value;
    }
}

/// _
int Py_UNICODE_MATCH()(PyUnicodeObject* string, size_t offset,
        PyUnicodeObject* substring
        )
{
    return (
            (*(string.str + offset) == *(substring.str))
            && !memcmp(string.str + offset, substring.str,
                substring.length * Py_UNICODE.sizeof
                )
           );
}


