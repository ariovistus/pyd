module deimos.python.unicodeobject;

import std.c.stdarg;
import std.c.string;
import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/unicodeobject.h:
/* The Python header explains:
 *   Unicode API names are mangled to assure that UCS-2 and UCS-4 builds
 *   produce different external names and thus cause import errors in
 *   case Python interpreters and extensions with mixed compiled in
 *   Unicode width assumptions are combined. */


version (Python_Unicode_UCS2) {
    version (Windows) {
        alias wchar Py_UNICODE;
    } else {
        alias ushort Py_UNICODE;
    }
} else {
    alias uint Py_UNICODE;
}
alias Py_UNICODE Py_UCS4;

struct PyUnicodeObject {
    mixin PyObject_HEAD;

    Py_ssize_t length;
    Py_UNICODE* str;
    C_long hash;
    PyObject* defenc;
}

__gshared PyTypeObject PyUnicode_Type;

// D translations of C macros:
int PyUnicode_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, &PyUnicode_Type);
}
int PyUnicode_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyUnicode_Type;
}

size_t PyUnicode_GET_SIZE()(PyUnicodeObject* op) {
    return op.length;
}
size_t PyUnicode_GET_DATA_SIZE()(PyUnicodeObject* op) {
    return op.length * Py_UNICODE.sizeof;
}
Py_UNICODE* PyUnicode_AS_UNICODE()(PyUnicodeObject* op) {
    return op.str;
}
const(char)* PyUnicode_AS_DATA()(PyUnicodeObject* op) {
    return cast(const(char)*) op.str;
}

enum Py_UNICODE Py_UNICODE_REPLACEMENT_CHARACTER = 0xFFFD;

version(Python_Unicode_UCS2) {
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

      /* Similar to PyUnicode_FromUnicode(), but u points to Latin-1 encoded bytes */
      PyObject* PyUnicode_FromStringAndSize(
              const(char)*u,        /* char buffer */
              Py_ssize_t size       /* size of buffer */
              );

      /* Similar to PyUnicode_FromUnicode(), but u points to null-terminated
         Latin-1 encoded bytes */
      PyObject* PyUnicode_FromString(
              const(char)*u        /* string */
              );
      PyObject * PyUnicode_FromFormatV(const(char)*, va_list);
      PyObject * PyUnicode_FromFormat(const(char)*, ...);

      /* Format the object based on the format_spec, as defined in PEP 3101
         (Advanced String Formatting). */
      PyObject * _PyUnicode_FormatAdvanced(PyObject *obj,
              Py_UNICODE *format_spec,
              Py_ssize_t format_spec_len);
      int PyUnicode_ClearFreeList();
      PyObject* PyUnicode_DecodeUTF7Stateful(
              const(char)*string,         /* UTF-7 encoded string */
              Py_ssize_t length,          /* size of string */
              const(char)*errors,         /* error handling */
              Py_ssize_t *consumed        /* bytes consumed */
              );
      PyObject* PyUnicode_DecodeUTF32(
              const(char)*string,         /* UTF-32 encoded string */
              Py_ssize_t length,          /* size of string */
              const(char)*errors,         /* error handling */
              int *byteorder              /* pointer to byteorder to use
                                             0=native;-1=LE,1=BE; updated on
                                             exit */
              );

      PyObject* PyUnicode_DecodeUTF32Stateful(
              const(char)*string,         /* UTF-32 encoded string */
              Py_ssize_t length,          /* size of string */
              const(char)*errors,         /* error handling */
              int *byteorder,             /* pointer to byteorder to use
                                             0=native;-1=LE,1=BE; updated on
                                             exit */
              Py_ssize_t *consumed        /* bytes consumed */
              );
      /* Returns a Python string using the UTF-32 encoding in native byte
         order. The string always starts with a BOM mark.  */

      PyObject* PyUnicode_AsUTF32String(
              PyObject *unicode           /* Unicode object */
              );

      /* Returns a Python string object holding the UTF-32 encoded value of
         the Unicode data.

         If byteorder is not 0, output is written according to the following
         byte order:

         byteorder == -1: little endian
         byteorder == 0:  native byte order (writes a BOM mark)
         byteorder == 1:  big endian

         If byteorder is 0, the output string will always start with the
         Unicode BOM mark (U+FEFF). In the other two modes, no BOM mark is
         prepended.

       */

      PyObject* PyUnicode_EncodeUTF32(
              const Py_UNICODE *data,     /* Unicode char buffer */
              Py_ssize_t length,          /* number of Py_UNICODE chars to encode */
              const(char)*errors,         /* error handling */
              int byteorder               /* byteorder to use 0=BOM+native;-1=LE,1=BE */
              );
      }

    PyObject *PyUnicode_FromUnicode(Py_UNICODE *u, Py_ssize_t size);
    Py_UNICODE *PyUnicode_AsUnicode(PyObject *unicode);
    Py_ssize_t PyUnicode_GetSize(PyObject *unicode);
    Py_UNICODE PyUnicode_GetMax();

    int PyUnicode_Resize(PyObject **unicode, Py_ssize_t length);
    PyObject *PyUnicode_FromEncodedObject(PyObject *obj, const(char) *encoding, const(char) *errors);
    PyObject *PyUnicode_FromObject(PyObject *obj);

    PyObject *PyUnicode_FromWideChar(const(wchar) *w, Py_ssize_t size);
    Py_ssize_t PyUnicode_AsWideChar(PyUnicodeObject *unicode, const(wchar) *w, Py_ssize_t size);

    PyObject *PyUnicode_FromOrdinal(int ordinal);

    PyObject *_PyUnicode_AsDefaultEncodedString(PyObject *, const(char)*);

    const(char)*PyUnicode_GetDefaultEncoding();
    int PyUnicode_SetDefaultEncoding(const(char)*encoding);

    PyObject *PyUnicode_Decode(const(char) *s, Py_ssize_t size, const(char) *encoding, const(char) *errors);

    version(Python_3_2_Or_Later) {
    /** Decode a Unicode object unicode and return the result as Python
      object. */

    PyObject* PyUnicode_AsDecodedObject(
            PyObject* unicode,          /* Unicode object */
            const(char)* encoding,       /* encoding */
            const(char)* errors          /* error handling */
            );
    /** Decode a Unicode object unicode and return the result as Unicode
      object. */

    PyObject* PyUnicode_AsDecodedUnicode(
            PyObject* unicode,          /* Unicode object */
            const(char)* encoding,       /* encoding */
            const(char)* errors          /* error handling */
            );
    }

    PyObject *PyUnicode_Encode(Py_UNICODE *s, Py_ssize_t size, const(char) *encoding, const(char) *errors);
    PyObject *PyUnicode_AsEncodedObject(PyObject *unicode, const(char) *encoding, const(char) *errors);
    PyObject *PyUnicode_AsEncodedString(PyObject *unicode, const(char) *encoding, const(char) *errors);

    version(Python_3_2_Or_Later) {
        /** Encodes a Unicode object and returns the result as Unicode
           object. */

        PyObject* PyUnicode_AsEncodedUnicode(
                PyObject* unicode,          /* Unicode object */
                const(char)* encoding,       /* encoding */
                const(char)* errors          /* error handling */
                );
    }

    PyObject *PyUnicode_DecodeUTF7(const(char) *string, Py_ssize_t length, const(char) *errors);
    PyObject *PyUnicode_EncodeUTF7(Py_UNICODE *data, Py_ssize_t length,
        int encodeSetO, int encodeWhiteSpace, const(char) *errors
      );

    PyObject *PyUnicode_DecodeUTF8(const(char) *string, Py_ssize_t length, const(char) *errors);
    PyObject *PyUnicode_DecodeUTF8Stateful(const(char) *string, Py_ssize_t length,
        const(char) *errors, Py_ssize_t *consumed
      );
    PyObject *PyUnicode_AsUTF8String(PyObject *unicode);
    PyObject *PyUnicode_EncodeUTF8(Py_UNICODE *data, Py_ssize_t length, const(char) *errors);

    PyObject *PyUnicode_DecodeUTF16(const(char) *string, Py_ssize_t length, const(char) *errors, int *byteorder);
    PyObject *PyUnicode_DecodeUTF16Stateful(const(char) *string, Py_ssize_t length,
        const(char) *errors, int *byteorder, Py_ssize_t *consumed
      );
    PyObject *PyUnicode_AsUTF16String(PyObject *unicode);
    PyObject *PyUnicode_EncodeUTF16(Py_UNICODE *data, Py_ssize_t length,
        const(char) *errors, int byteorder
      );

    PyObject *PyUnicode_DecodeUnicodeEscape(const(char) *string, Py_ssize_t length, const(char) *errors);
    PyObject *PyUnicode_AsUnicodeEscapeString(PyObject *unicode);
    PyObject *PyUnicode_EncodeUnicodeEscape(Py_UNICODE *data, Py_ssize_t length);
    PyObject *PyUnicode_DecodeRawUnicodeEscape(const(char) *string, Py_ssize_t length, const(char) *errors);
    PyObject *PyUnicode_AsRawUnicodeEscapeString(PyObject *unicode);
    PyObject *PyUnicode_EncodeRawUnicodeEscape(Py_UNICODE *data, Py_ssize_t length);

    PyObject *_PyUnicode_DecodeUnicodeInternal(const(char) *string, Py_ssize_t length, const(char) *errors);

    PyObject *PyUnicode_DecodeLatin1(const(char) *string, Py_ssize_t length, const(char) *errors);
    PyObject *PyUnicode_AsLatin1String(PyObject *unicode);
    PyObject *PyUnicode_EncodeLatin1(Py_UNICODE *data, Py_ssize_t length, const(char) *errors);

    PyObject *PyUnicode_DecodeASCII(const(char) *string, Py_ssize_t length, const(char) *errors);
    PyObject *PyUnicode_AsASCIIString(PyObject *unicode);
    PyObject *PyUnicode_EncodeASCII(Py_UNICODE *data, Py_ssize_t length, const(char) *errors);

    PyObject *PyUnicode_DecodeCharmap(const(char) *string, Py_ssize_t length,
        PyObject *mapping, const(char) *errors
      );
    PyObject *PyUnicode_AsCharmapString(PyObject *unicode, PyObject *mapping);
    PyObject *PyUnicode_EncodeCharmap(Py_UNICODE *data, Py_ssize_t length,
        PyObject *mapping, const(char) *errors
      );
    PyObject *PyUnicode_TranslateCharmap(Py_UNICODE *data, Py_ssize_t length,
        PyObject *table, const(char) *errors
      );

    version (Windows) {
      PyObject *PyUnicode_DecodeMBCS(const(char) *string, Py_ssize_t length, const(char) *errors);
      PyObject *PyUnicode_AsMBCSString(PyObject *unicode);
      PyObject *PyUnicode_EncodeMBCS(Py_UNICODE *data, Py_ssize_t length, const(char) *errors);
    }

    int PyUnicode_EncodeDecimal(Py_UNICODE *s, Py_ssize_t length, char *output, const(char) *errors);

    /** Concat two strings giving a new Unicode string. */
    PyObject *PyUnicode_Concat(PyObject *left, PyObject *right);

    version(Python_3_2_Or_Later) {
        /** Concat two strings and put the result in *pleft
           (sets *pleft to NULL on error) */

        void PyUnicode_Append(
                PyObject** pleft,           /* Pointer to left string */
                PyObject* right             /* Right string */
                );

        /** Concat two strings, put the result in *pleft and drop the right object
           (sets *pleft to NULL on error) */

        void PyUnicode_AppendAndDel(
                PyObject** pleft,           /* Pointer to left string */
                PyObject* right             /* Right string */
                );
    }

    /** Split a string giving a list of Unicode strings.

      If sep is NULL, splitting will be done at all whitespace
      substrings. Otherwise, splits occur at the given separator.

      At most maxsplit splits will be done. If negative, no limit is set.

      Separators are not included in the resulting list.

     */
    PyObject *PyUnicode_Split(PyObject *s, PyObject *sep, Py_ssize_t maxsplit);

    /** Ditto PyUnicode_Split, but split at line breaks.

       CRLF is considered to be one line break. Line breaks are not
       included in the resulting list. */
    PyObject *PyUnicode_Splitlines(PyObject *s, int keepends);
    version(Python_2_5_Or_Later) {
        /** Partition a string using a given separator. */

        PyObject* PyUnicode_Partition(
                PyObject* s,                /* String to partition */
                PyObject* sep               /* String separator */
                );

        /** Partition a string using a given separator, searching from the end of the
           string. */

        PyObject* PyUnicode_RPartition(
                PyObject* s,                /* String to partition */
                PyObject* sep               /* String separator */
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
    PyObject *PyUnicode_RSplit(PyObject *s, PyObject *sep, Py_ssize_t maxsplit);

    /** Translate a string by applying a character mapping table to it and
      return the resulting Unicode object.

      The mapping table must map Unicode ordinal integers to Unicode
      ordinal integers or None (causing deletion of the character).

      Mapping tables may be dictionaries or sequences. Unmapped character
      ordinals (ones which cause a LookupError) are left untouched and
      are copied as-is.

     */
    PyObject *PyUnicode_Translate(PyObject *str, PyObject *table, const(char) *errors);

    /** Join a sequence of strings using the given separator and return
      the resulting Unicode string. */
    PyObject *PyUnicode_Join(PyObject *separator, PyObject *seq);

    /** Return 1 if substr matches str[start:end] at the given tail end, 0
      otherwise. */
    Py_ssize_t PyUnicode_Tailmatch(PyObject *str, PyObject *substr,
        Py_ssize_t start, Py_ssize_t end, int direction
      );

    /** Return the first position of substr in str[start:end] using the
      given search direction or -1 if not found. -2 is returned in case
      an error occurred and an exception is set. */
    Py_ssize_t PyUnicode_Find(
            PyObject *str, 
            PyObject *substr,
            Py_ssize_t start, 
            Py_ssize_t end, 
            int direction
      );

    /** Count the number of occurrences of substr in str[start:end]. */
    Py_ssize_t PyUnicode_Count(
            PyObject *str, 
            PyObject *substr, 
            Py_ssize_t start, 
            Py_ssize_t end);

    /** Replace at most maxcount occurrences of substr in str with replstr
       and return the resulting Unicode object. */
    PyObject* PyUnicode_Replace(
            PyObject *str, 
            PyObject *substr,
            PyObject *replstr, 
            Py_ssize_t maxcount
      );

    /** Compare two strings and return -1, 0, 1 for less than, equal,
      greater than resp. */
    int PyUnicode_Compare(PyObject *left, PyObject *right);
    version(Python_3_2_Or_Later) {
        /** Compare two strings and return -1, 0, 1 for less than, equal,
          greater than resp. */
        int PyUnicode_CompareWithASCIIString(
                PyObject* left,
                const(char)* right           /* ASCII-encoded string */
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

        PyObject* PyUnicode_RichCompare(
                PyObject* left,             /* Left string */
                PyObject* right,            /* Right string */
                int op                      /* Operation: Py_EQ, Py_NE, Py_GT, etc. */
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

    version(Python_3_2_Or_Later) {
        int PyUnicode_IsIdentifier(PyObject* s);
    }


    int _PyUnicode_IsLowercase(Py_UNICODE ch);
    int _PyUnicode_IsUppercase(Py_UNICODE ch);
    int _PyUnicode_IsTitlecase(Py_UNICODE ch);
    int _PyUnicode_IsWhitespace(Py_UNICODE ch);
    int _PyUnicode_IsLinebreak(Py_UNICODE ch);
    Py_UNICODE _PyUnicode_ToLowercase(Py_UNICODE ch);
    Py_UNICODE _PyUnicode_ToUppercase(Py_UNICODE ch);
    Py_UNICODE _PyUnicode_ToTitlecase(Py_UNICODE ch);
    int _PyUnicode_ToDecimalDigit(Py_UNICODE ch);
    int _PyUnicode_ToDigit(Py_UNICODE ch);
    double _PyUnicode_ToNumeric(Py_UNICODE ch);
    int _PyUnicode_IsDecimalDigit(Py_UNICODE ch);
    int _PyUnicode_IsDigit(Py_UNICODE ch);
    int _PyUnicode_IsNumeric(Py_UNICODE ch);
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
version(Python_Unicode_UCS2) {

    version(Python_2_6_Or_Later) {

      /* Similar to PyUnicode_FromUnicode(), but u points to Latin-1 encoded bytes */
      PyObject* PyUnicodeUCS2_FromStringAndSize(
              const(char)*u,        /* char buffer */
              Py_ssize_t size       /* size of buffer */
              );
alias PyUnicodeUCS2_FromStringAndSize PyUnicode_FromStringAndSize;


      /* Similar to PyUnicode_FromUnicode(), but u points to null-terminated
         Latin-1 encoded bytes */
      PyObject* PyUnicodeUCS2_FromString(
              const(char)*u        /* string */
              );
alias PyUnicodeUCS2_FromString PyUnicode_FromString;

      PyObject * PyUnicodeUCS2_FromFormatV(const(char)*, va_list);
alias PyUnicodeUCS2_FromFormatV PyUnicode_FromFormatV;

      PyObject * PyUnicodeUCS2_FromFormat(const(char)*, ...);
alias PyUnicodeUCS2_FromFormat PyUnicode_FromFormat;


      /* Format the object based on the format_spec, as defined in PEP 3101
         (Advanced String Formatting). */
      PyObject * _PyUnicodeUCS2_FormatAdvanced(PyObject *obj,
              Py_UNICODE *format_spec,
              Py_ssize_t format_spec_len);
alias _PyUnicodeUCS2_FormatAdvanced _PyUnicode_FormatAdvanced;

      int PyUnicodeUCS2_ClearFreeList();
alias PyUnicodeUCS2_ClearFreeList PyUnicode_ClearFreeList;

      PyObject* PyUnicodeUCS2_DecodeUTF7Stateful(
              const(char)*string,         /* UTF-7 encoded string */
              Py_ssize_t length,          /* size of string */
              const(char)*errors,         /* error handling */
              Py_ssize_t *consumed        /* bytes consumed */
              );
alias PyUnicodeUCS2_DecodeUTF7Stateful PyUnicode_DecodeUTF7Stateful;

      PyObject* PyUnicodeUCS2_DecodeUTF32(
              const(char)*string,         /* UTF-32 encoded string */
              Py_ssize_t length,          /* size of string */
              const(char)*errors,         /* error handling */
              int *byteorder              /* pointer to byteorder to use
                                             0=native;-1=LE,1=BE; updated on
                                             exit */
              );
alias PyUnicodeUCS2_DecodeUTF32 PyUnicode_DecodeUTF32;


      PyObject* PyUnicodeUCS2_DecodeUTF32Stateful(
              const(char)*string,         /* UTF-32 encoded string */
              Py_ssize_t length,          /* size of string */
              const(char)*errors,         /* error handling */
              int *byteorder,             /* pointer to byteorder to use
                                             0=native;-1=LE,1=BE; updated on
                                             exit */
              Py_ssize_t *consumed        /* bytes consumed */
              );
alias PyUnicodeUCS2_DecodeUTF32Stateful PyUnicode_DecodeUTF32Stateful;

      /* Returns a Python string using the UTF-32 encoding in native byte
         order. The string always starts with a BOM mark.  */

      PyObject* PyUnicodeUCS2_AsUTF32String(
              PyObject *unicode           /* Unicode object */
              );
alias PyUnicodeUCS2_AsUTF32String PyUnicode_AsUTF32String;


      /* Returns a Python string object holding the UTF-32 encoded value of
         the Unicode data.

         If byteorder is not 0, output is written according to the following
         byte order:

         byteorder == -1: little endian
         byteorder == 0:  native byte order (writes a BOM mark)
         byteorder == 1:  big endian

         If byteorder is 0, the output string will always start with the
         Unicode BOM mark (U+FEFF). In the other two modes, no BOM mark is
         prepended.

       */

      PyObject* PyUnicodeUCS2_EncodeUTF32(
              const Py_UNICODE *data,     /* Unicode char buffer */
              Py_ssize_t length,          /* number of Py_UNICODE chars to encode */
              const(char)*errors,         /* error handling */
              int byteorder               /* byteorder to use 0=BOM+native;-1=LE,1=BE */
              );
alias PyUnicodeUCS2_EncodeUTF32 PyUnicode_EncodeUTF32;

      }

    PyObject *PyUnicodeUCS2_FromUnicode(Py_UNICODE *u, Py_ssize_t size);
alias PyUnicodeUCS2_FromUnicode PyUnicode_FromUnicode;

    Py_UNICODE *PyUnicodeUCS2_AsUnicode(PyObject *unicode);
alias PyUnicodeUCS2_AsUnicode PyUnicode_AsUnicode;

    Py_ssize_t PyUnicodeUCS2_GetSize(PyObject *unicode);
alias PyUnicodeUCS2_GetSize PyUnicode_GetSize;

    Py_UNICODE PyUnicodeUCS2_GetMax();
alias PyUnicodeUCS2_GetMax PyUnicode_GetMax;


    int PyUnicodeUCS2_Resize(PyObject **unicode, Py_ssize_t length);
alias PyUnicodeUCS2_Resize PyUnicode_Resize;

    PyObject *PyUnicodeUCS2_FromEncodedObject(PyObject *obj, const(char) *encoding, const(char) *errors);
alias PyUnicodeUCS2_FromEncodedObject PyUnicode_FromEncodedObject;

    PyObject *PyUnicodeUCS2_FromObject(PyObject *obj);
alias PyUnicodeUCS2_FromObject PyUnicode_FromObject;


    PyObject *PyUnicodeUCS2_FromWideChar(const(wchar) *w, Py_ssize_t size);
alias PyUnicodeUCS2_FromWideChar PyUnicode_FromWideChar;

    Py_ssize_t PyUnicodeUCS2_AsWideChar(PyUnicodeObject *unicode, const(wchar) *w, Py_ssize_t size);
alias PyUnicodeUCS2_AsWideChar PyUnicode_AsWideChar;


    PyObject *PyUnicodeUCS2_FromOrdinal(int ordinal);
alias PyUnicodeUCS2_FromOrdinal PyUnicode_FromOrdinal;


    PyObject *_PyUnicodeUCS2_AsDefaultEncodedString(PyObject *, const(char)*);
alias _PyUnicodeUCS2_AsDefaultEncodedString _PyUnicode_AsDefaultEncodedString;


    const(char)*PyUnicodeUCS2_GetDefaultEncoding();
alias PyUnicodeUCS2_GetDefaultEncoding PyUnicode_GetDefaultEncoding;

    int PyUnicodeUCS2_SetDefaultEncoding(const(char)*encoding);
alias PyUnicodeUCS2_SetDefaultEncoding PyUnicode_SetDefaultEncoding;


    PyObject *PyUnicodeUCS2_Decode(const(char) *s, Py_ssize_t size, const(char) *encoding, const(char) *errors);
alias PyUnicodeUCS2_Decode PyUnicode_Decode;


    version(Python_3_2_Or_Later) {
    /** Decode a Unicode object unicode and return the result as Python
      object. */

    PyObject* PyUnicodeUCS2_AsDecodedObject(
            PyObject* unicode,          /* Unicode object */
            const(char)* encoding,       /* encoding */
            const(char)* errors          /* error handling */
            );
alias PyUnicodeUCS2_AsDecodedObject PyUnicode_AsDecodedObject;

    /** Decode a Unicode object unicode and return the result as Unicode
      object. */

    PyObject* PyUnicodeUCS2_AsDecodedUnicode(
            PyObject* unicode,          /* Unicode object */
            const(char)* encoding,       /* encoding */
            const(char)* errors          /* error handling */
            );
alias PyUnicodeUCS2_AsDecodedUnicode PyUnicode_AsDecodedUnicode;

    }

    PyObject *PyUnicodeUCS2_Encode(Py_UNICODE *s, Py_ssize_t size, const(char) *encoding, const(char) *errors);
alias PyUnicodeUCS2_Encode PyUnicode_Encode;

    PyObject *PyUnicodeUCS2_AsEncodedObject(PyObject *unicode, const(char) *encoding, const(char) *errors);
alias PyUnicodeUCS2_AsEncodedObject PyUnicode_AsEncodedObject;

    PyObject *PyUnicodeUCS2_AsEncodedString(PyObject *unicode, const(char) *encoding, const(char) *errors);
alias PyUnicodeUCS2_AsEncodedString PyUnicode_AsEncodedString;


    version(Python_3_2_Or_Later) {
        /** Encodes a Unicode object and returns the result as Unicode
           object. */

        PyObject* PyUnicodeUCS2_AsEncodedUnicode(
                PyObject* unicode,          /* Unicode object */
                const(char)* encoding,       /* encoding */
                const(char)* errors          /* error handling */
                );
alias PyUnicodeUCS2_AsEncodedUnicode PyUnicode_AsEncodedUnicode;

    }

    PyObject *PyUnicodeUCS2_DecodeUTF7(const(char) *string, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS2_DecodeUTF7 PyUnicode_DecodeUTF7;

    PyObject *PyUnicodeUCS2_EncodeUTF7(Py_UNICODE *data, Py_ssize_t length,
        int encodeSetO, int encodeWhiteSpace, const(char) *errors
      );
alias PyUnicodeUCS2_EncodeUTF7 PyUnicode_EncodeUTF7;


    PyObject *PyUnicodeUCS2_DecodeUTF8(const(char) *string, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS2_DecodeUTF8 PyUnicode_DecodeUTF8;

    PyObject *PyUnicodeUCS2_DecodeUTF8Stateful(const(char) *string, Py_ssize_t length,
        const(char) *errors, Py_ssize_t *consumed
      );
alias PyUnicodeUCS2_DecodeUTF8Stateful PyUnicode_DecodeUTF8Stateful;

    PyObject *PyUnicodeUCS2_AsUTF8String(PyObject *unicode);
alias PyUnicodeUCS2_AsUTF8String PyUnicode_AsUTF8String;

    PyObject *PyUnicodeUCS2_EncodeUTF8(Py_UNICODE *data, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS2_EncodeUTF8 PyUnicode_EncodeUTF8;


    PyObject *PyUnicodeUCS2_DecodeUTF16(const(char) *string, Py_ssize_t length, const(char) *errors, int *byteorder);
alias PyUnicodeUCS2_DecodeUTF16 PyUnicode_DecodeUTF16;

    PyObject *PyUnicodeUCS2_DecodeUTF16Stateful(const(char) *string, Py_ssize_t length,
        const(char) *errors, int *byteorder, Py_ssize_t *consumed
      );
alias PyUnicodeUCS2_DecodeUTF16Stateful PyUnicode_DecodeUTF16Stateful;

    PyObject *PyUnicodeUCS2_AsUTF16String(PyObject *unicode);
alias PyUnicodeUCS2_AsUTF16String PyUnicode_AsUTF16String;

    PyObject *PyUnicodeUCS2_EncodeUTF16(Py_UNICODE *data, Py_ssize_t length,
        const(char) *errors, int byteorder
      );
alias PyUnicodeUCS2_EncodeUTF16 PyUnicode_EncodeUTF16;


    PyObject *PyUnicodeUCS2_DecodeUnicodeEscape(const(char) *string, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS2_DecodeUnicodeEscape PyUnicode_DecodeUnicodeEscape;

    PyObject *PyUnicodeUCS2_AsUnicodeEscapeString(PyObject *unicode);
alias PyUnicodeUCS2_AsUnicodeEscapeString PyUnicode_AsUnicodeEscapeString;

    PyObject *PyUnicodeUCS2_EncodeUnicodeEscape(Py_UNICODE *data, Py_ssize_t length);
alias PyUnicodeUCS2_EncodeUnicodeEscape PyUnicode_EncodeUnicodeEscape;

    PyObject *PyUnicodeUCS2_DecodeRawUnicodeEscape(const(char) *string, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS2_DecodeRawUnicodeEscape PyUnicode_DecodeRawUnicodeEscape;

    PyObject *PyUnicodeUCS2_AsRawUnicodeEscapeString(PyObject *unicode);
alias PyUnicodeUCS2_AsRawUnicodeEscapeString PyUnicode_AsRawUnicodeEscapeString;

    PyObject *PyUnicodeUCS2_EncodeRawUnicodeEscape(Py_UNICODE *data, Py_ssize_t length);
alias PyUnicodeUCS2_EncodeRawUnicodeEscape PyUnicode_EncodeRawUnicodeEscape;


    PyObject *_PyUnicodeUCS2_DecodeUnicodeInternal(const(char) *string, Py_ssize_t length, const(char) *errors);
alias _PyUnicodeUCS2_DecodeUnicodeInternal _PyUnicode_DecodeUnicodeInternal;


    PyObject *PyUnicodeUCS2_DecodeLatin1(const(char) *string, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS2_DecodeLatin1 PyUnicode_DecodeLatin1;

    PyObject *PyUnicodeUCS2_AsLatin1String(PyObject *unicode);
alias PyUnicodeUCS2_AsLatin1String PyUnicode_AsLatin1String;

    PyObject *PyUnicodeUCS2_EncodeLatin1(Py_UNICODE *data, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS2_EncodeLatin1 PyUnicode_EncodeLatin1;


    PyObject *PyUnicodeUCS2_DecodeASCII(const(char) *string, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS2_DecodeASCII PyUnicode_DecodeASCII;

    PyObject *PyUnicodeUCS2_AsASCIIString(PyObject *unicode);
alias PyUnicodeUCS2_AsASCIIString PyUnicode_AsASCIIString;

    PyObject *PyUnicodeUCS2_EncodeASCII(Py_UNICODE *data, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS2_EncodeASCII PyUnicode_EncodeASCII;


    PyObject *PyUnicodeUCS2_DecodeCharmap(const(char) *string, Py_ssize_t length,
        PyObject *mapping, const(char) *errors
      );
alias PyUnicodeUCS2_DecodeCharmap PyUnicode_DecodeCharmap;

    PyObject *PyUnicodeUCS2_AsCharmapString(PyObject *unicode, PyObject *mapping);
alias PyUnicodeUCS2_AsCharmapString PyUnicode_AsCharmapString;

    PyObject *PyUnicodeUCS2_EncodeCharmap(Py_UNICODE *data, Py_ssize_t length,
        PyObject *mapping, const(char) *errors
      );
alias PyUnicodeUCS2_EncodeCharmap PyUnicode_EncodeCharmap;

    PyObject *PyUnicodeUCS2_TranslateCharmap(Py_UNICODE *data, Py_ssize_t length,
        PyObject *table, const(char) *errors
      );
alias PyUnicodeUCS2_TranslateCharmap PyUnicode_TranslateCharmap;


    version (Windows) {
      PyObject *PyUnicodeUCS2_DecodeMBCS(const(char) *string, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS2_DecodeMBCS PyUnicode_DecodeMBCS;

      PyObject *PyUnicodeUCS2_AsMBCSString(PyObject *unicode);
alias PyUnicodeUCS2_AsMBCSString PyUnicode_AsMBCSString;

      PyObject *PyUnicodeUCS2_EncodeMBCS(Py_UNICODE *data, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS2_EncodeMBCS PyUnicode_EncodeMBCS;

    }

    int PyUnicodeUCS2_EncodeDecimal(Py_UNICODE *s, Py_ssize_t length, char *output, const(char) *errors);
alias PyUnicodeUCS2_EncodeDecimal PyUnicode_EncodeDecimal;


    /** Concat two strings giving a new Unicode string. */
    PyObject *PyUnicodeUCS2_Concat(PyObject *left, PyObject *right);
alias PyUnicodeUCS2_Concat PyUnicode_Concat;


    version(Python_3_2_Or_Later) {
        /** Concat two strings and put the result in *pleft
           (sets *pleft to NULL on error) */

        void PyUnicodeUCS2_Append(
                PyObject** pleft,           /* Pointer to left string */
                PyObject* right             /* Right string */
                );
alias PyUnicodeUCS2_Append PyUnicode_Append;


        /** Concat two strings, put the result in *pleft and drop the right object
           (sets *pleft to NULL on error) */

        void PyUnicodeUCS2_AppendAndDel(
                PyObject** pleft,           /* Pointer to left string */
                PyObject* right             /* Right string */
                );
alias PyUnicodeUCS2_AppendAndDel PyUnicode_AppendAndDel;

    }

    /** Split a string giving a list of Unicode strings.

      If sep is NULL, splitting will be done at all whitespace
      substrings. Otherwise, splits occur at the given separator.

      At most maxsplit splits will be done. If negative, no limit is set.

      Separators are not included in the resulting list.

     */
    PyObject *PyUnicodeUCS2_Split(PyObject *s, PyObject *sep, Py_ssize_t maxsplit);
alias PyUnicodeUCS2_Split PyUnicode_Split;


    /** Ditto PyUnicode_Split, but split at line breaks.

       CRLF is considered to be one line break. Line breaks are not
       included in the resulting list. */
    PyObject *PyUnicodeUCS2_Splitlines(PyObject *s, int keepends);
alias PyUnicodeUCS2_Splitlines PyUnicode_Splitlines;

    version(Python_2_5_Or_Later) {
        /** Partition a string using a given separator. */

        PyObject* PyUnicodeUCS2_Partition(
                PyObject* s,                /* String to partition */
                PyObject* sep               /* String separator */
                );
alias PyUnicodeUCS2_Partition PyUnicode_Partition;


        /** Partition a string using a given separator, searching from the end of the
           string. */

        PyObject* PyUnicodeUCS2_RPartition(
                PyObject* s,                /* String to partition */
                PyObject* sep               /* String separator */
                );
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
    PyObject *PyUnicodeUCS2_RSplit(PyObject *s, PyObject *sep, Py_ssize_t maxsplit);
alias PyUnicodeUCS2_RSplit PyUnicode_RSplit;


    /** Translate a string by applying a character mapping table to it and
      return the resulting Unicode object.

      The mapping table must map Unicode ordinal integers to Unicode
      ordinal integers or None (causing deletion of the character).

      Mapping tables may be dictionaries or sequences. Unmapped character
      ordinals (ones which cause a LookupError) are left untouched and
      are copied as-is.

     */
    PyObject *PyUnicodeUCS2_Translate(PyObject *str, PyObject *table, const(char) *errors);
alias PyUnicodeUCS2_Translate PyUnicode_Translate;


    /** Join a sequence of strings using the given separator and return
      the resulting Unicode string. */
    PyObject *PyUnicodeUCS2_Join(PyObject *separator, PyObject *seq);
alias PyUnicodeUCS2_Join PyUnicode_Join;


    /** Return 1 if substr matches str[start:end] at the given tail end, 0
      otherwise. */
    Py_ssize_t PyUnicodeUCS2_Tailmatch(PyObject *str, PyObject *substr,
        Py_ssize_t start, Py_ssize_t end, int direction
      );
alias PyUnicodeUCS2_Tailmatch PyUnicode_Tailmatch;


    /** Return the first position of substr in str[start:end] using the
      given search direction or -1 if not found. -2 is returned in case
      an error occurred and an exception is set. */
    Py_ssize_t PyUnicodeUCS2_Find(
            PyObject *str, 
            PyObject *substr,
            Py_ssize_t start, 
            Py_ssize_t end, 
            int direction
      );
alias PyUnicodeUCS2_Find PyUnicode_Find;


    /** Count the number of occurrences of substr in str[start:end]. */
    Py_ssize_t PyUnicodeUCS2_Count(
            PyObject *str, 
            PyObject *substr, 
            Py_ssize_t start, 
            Py_ssize_t end);
alias PyUnicodeUCS2_Count PyUnicode_Count;


    /** Replace at most maxcount occurrences of substr in str with replstr
       and return the resulting Unicode object. */
    PyObject* PyUnicodeUCS2_Replace(
            PyObject *str, 
            PyObject *substr,
            PyObject *replstr, 
            Py_ssize_t maxcount
      );
alias PyUnicodeUCS2_Replace PyUnicode_Replace;


    /** Compare two strings and return -1, 0, 1 for less than, equal,
      greater than resp. */
    int PyUnicodeUCS2_Compare(PyObject *left, PyObject *right);
alias PyUnicodeUCS2_Compare PyUnicode_Compare;

    version(Python_3_2_Or_Later) {
        /** Compare two strings and return -1, 0, 1 for less than, equal,
          greater than resp. */
        int PyUnicodeUCS2_CompareWithASCIIString(
                PyObject* left,
                const(char)* right           /* ASCII-encoded string */
                );
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

        PyObject* PyUnicodeUCS2_RichCompare(
                PyObject* left,             /* Left string */
                PyObject* right,            /* Right string */
                int op                      /* Operation: Py_EQ, Py_NE, Py_GT, etc. */
                );
alias PyUnicodeUCS2_RichCompare PyUnicode_RichCompare;

    }

    /** Apply a argument tuple or dictionary to a format string and return
      the resulting Unicode string. */
    PyObject* PyUnicodeUCS2_Format(PyObject* format, PyObject* args);
alias PyUnicodeUCS2_Format PyUnicode_Format;


    /** Checks whether element is contained in container and return 1/0
       accordingly.

       element has to coerce to an one element Unicode string. -1 is
       returned in case of an error. */
    int PyUnicodeUCS2_Contains(PyObject* container, PyObject* element);
alias PyUnicodeUCS2_Contains PyUnicode_Contains;


    version(Python_3_2_Or_Later) {
        int PyUnicodeUCS2_IsIdentifier(PyObject* s);
alias PyUnicodeUCS2_IsIdentifier PyUnicode_IsIdentifier;

    }


    int _PyUnicodeUCS2_IsLowercase(Py_UNICODE ch);
alias _PyUnicodeUCS2_IsLowercase _PyUnicode_IsLowercase;

    int _PyUnicodeUCS2_IsUppercase(Py_UNICODE ch);
alias _PyUnicodeUCS2_IsUppercase _PyUnicode_IsUppercase;

    int _PyUnicodeUCS2_IsTitlecase(Py_UNICODE ch);
alias _PyUnicodeUCS2_IsTitlecase _PyUnicode_IsTitlecase;

    int _PyUnicodeUCS2_IsWhitespace(Py_UNICODE ch);
alias _PyUnicodeUCS2_IsWhitespace _PyUnicode_IsWhitespace;

    int _PyUnicodeUCS2_IsLinebreak(Py_UNICODE ch);
alias _PyUnicodeUCS2_IsLinebreak _PyUnicode_IsLinebreak;

    Py_UNICODE _PyUnicodeUCS2_ToLowercase(Py_UNICODE ch);
alias _PyUnicodeUCS2_ToLowercase _PyUnicode_ToLowercase;

    Py_UNICODE _PyUnicodeUCS2_ToUppercase(Py_UNICODE ch);
alias _PyUnicodeUCS2_ToUppercase _PyUnicode_ToUppercase;

    Py_UNICODE _PyUnicodeUCS2_ToTitlecase(Py_UNICODE ch);
alias _PyUnicodeUCS2_ToTitlecase _PyUnicode_ToTitlecase;

    int _PyUnicodeUCS2_ToDecimalDigit(Py_UNICODE ch);
alias _PyUnicodeUCS2_ToDecimalDigit _PyUnicode_ToDecimalDigit;

    int _PyUnicodeUCS2_ToDigit(Py_UNICODE ch);
alias _PyUnicodeUCS2_ToDigit _PyUnicode_ToDigit;

    double _PyUnicodeUCS2_ToNumeric(Py_UNICODE ch);
alias _PyUnicodeUCS2_ToNumeric _PyUnicode_ToNumeric;

    int _PyUnicodeUCS2_IsDecimalDigit(Py_UNICODE ch);
alias _PyUnicodeUCS2_IsDecimalDigit _PyUnicode_IsDecimalDigit;

    int _PyUnicodeUCS2_IsDigit(Py_UNICODE ch);
alias _PyUnicodeUCS2_IsDigit _PyUnicode_IsDigit;

    int _PyUnicodeUCS2_IsNumeric(Py_UNICODE ch);
alias _PyUnicodeUCS2_IsNumeric _PyUnicode_IsNumeric;

    int _PyUnicodeUCS2_IsAlpha(Py_UNICODE ch);
alias _PyUnicodeUCS2_IsAlpha _PyUnicode_IsAlpha;

}else{

    version(Python_2_6_Or_Later) {

      /* Similar to PyUnicode_FromUnicode(), but u points to Latin-1 encoded bytes */
      PyObject* PyUnicodeUCS4_FromStringAndSize(
              const(char)*u,        /* char buffer */
              Py_ssize_t size       /* size of buffer */
              );
alias PyUnicodeUCS4_FromStringAndSize PyUnicode_FromStringAndSize;


      /* Similar to PyUnicode_FromUnicode(), but u points to null-terminated
         Latin-1 encoded bytes */
      PyObject* PyUnicodeUCS4_FromString(
              const(char)*u        /* string */
              );
alias PyUnicodeUCS4_FromString PyUnicode_FromString;

      PyObject * PyUnicodeUCS4_FromFormatV(const(char)*, va_list);
alias PyUnicodeUCS4_FromFormatV PyUnicode_FromFormatV;

      PyObject * PyUnicodeUCS4_FromFormat(const(char)*, ...);
alias PyUnicodeUCS4_FromFormat PyUnicode_FromFormat;


      /* Format the object based on the format_spec, as defined in PEP 3101
         (Advanced String Formatting). */
      PyObject * _PyUnicodeUCS4_FormatAdvanced(PyObject *obj,
              Py_UNICODE *format_spec,
              Py_ssize_t format_spec_len);
alias _PyUnicodeUCS4_FormatAdvanced _PyUnicode_FormatAdvanced;

      int PyUnicodeUCS4_ClearFreeList();
alias PyUnicodeUCS4_ClearFreeList PyUnicode_ClearFreeList;

      PyObject* PyUnicodeUCS4_DecodeUTF7Stateful(
              const(char)*string,         /* UTF-7 encoded string */
              Py_ssize_t length,          /* size of string */
              const(char)*errors,         /* error handling */
              Py_ssize_t *consumed        /* bytes consumed */
              );
alias PyUnicodeUCS4_DecodeUTF7Stateful PyUnicode_DecodeUTF7Stateful;

      PyObject* PyUnicodeUCS4_DecodeUTF32(
              const(char)*string,         /* UTF-32 encoded string */
              Py_ssize_t length,          /* size of string */
              const(char)*errors,         /* error handling */
              int *byteorder              /* pointer to byteorder to use
                                             0=native;-1=LE,1=BE; updated on
                                             exit */
              );
alias PyUnicodeUCS4_DecodeUTF32 PyUnicode_DecodeUTF32;


      PyObject* PyUnicodeUCS4_DecodeUTF32Stateful(
              const(char)*string,         /* UTF-32 encoded string */
              Py_ssize_t length,          /* size of string */
              const(char)*errors,         /* error handling */
              int *byteorder,             /* pointer to byteorder to use
                                             0=native;-1=LE,1=BE; updated on
                                             exit */
              Py_ssize_t *consumed        /* bytes consumed */
              );
alias PyUnicodeUCS4_DecodeUTF32Stateful PyUnicode_DecodeUTF32Stateful;

      /* Returns a Python string using the UTF-32 encoding in native byte
         order. The string always starts with a BOM mark.  */

      PyObject* PyUnicodeUCS4_AsUTF32String(
              PyObject *unicode           /* Unicode object */
              );
alias PyUnicodeUCS4_AsUTF32String PyUnicode_AsUTF32String;


      /* Returns a Python string object holding the UTF-32 encoded value of
         the Unicode data.

         If byteorder is not 0, output is written according to the following
         byte order:

         byteorder == -1: little endian
         byteorder == 0:  native byte order (writes a BOM mark)
         byteorder == 1:  big endian

         If byteorder is 0, the output string will always start with the
         Unicode BOM mark (U+FEFF). In the other two modes, no BOM mark is
         prepended.

       */

      PyObject* PyUnicodeUCS4_EncodeUTF32(
              const Py_UNICODE *data,     /* Unicode char buffer */
              Py_ssize_t length,          /* number of Py_UNICODE chars to encode */
              const(char)*errors,         /* error handling */
              int byteorder               /* byteorder to use 0=BOM+native;-1=LE,1=BE */
              );
alias PyUnicodeUCS4_EncodeUTF32 PyUnicode_EncodeUTF32;

      }

    PyObject *PyUnicodeUCS4_FromUnicode(Py_UNICODE *u, Py_ssize_t size);
alias PyUnicodeUCS4_FromUnicode PyUnicode_FromUnicode;

    Py_UNICODE *PyUnicodeUCS4_AsUnicode(PyObject *unicode);
alias PyUnicodeUCS4_AsUnicode PyUnicode_AsUnicode;

    Py_ssize_t PyUnicodeUCS4_GetSize(PyObject *unicode);
alias PyUnicodeUCS4_GetSize PyUnicode_GetSize;

    Py_UNICODE PyUnicodeUCS4_GetMax();
alias PyUnicodeUCS4_GetMax PyUnicode_GetMax;


    int PyUnicodeUCS4_Resize(PyObject **unicode, Py_ssize_t length);
alias PyUnicodeUCS4_Resize PyUnicode_Resize;

    PyObject *PyUnicodeUCS4_FromEncodedObject(PyObject *obj, const(char) *encoding, const(char) *errors);
alias PyUnicodeUCS4_FromEncodedObject PyUnicode_FromEncodedObject;

    PyObject *PyUnicodeUCS4_FromObject(PyObject *obj);
alias PyUnicodeUCS4_FromObject PyUnicode_FromObject;


    PyObject *PyUnicodeUCS4_FromWideChar(const(wchar) *w, Py_ssize_t size);
alias PyUnicodeUCS4_FromWideChar PyUnicode_FromWideChar;

    Py_ssize_t PyUnicodeUCS4_AsWideChar(PyUnicodeObject *unicode, const(wchar) *w, Py_ssize_t size);
alias PyUnicodeUCS4_AsWideChar PyUnicode_AsWideChar;


    PyObject *PyUnicodeUCS4_FromOrdinal(int ordinal);
alias PyUnicodeUCS4_FromOrdinal PyUnicode_FromOrdinal;


    PyObject *_PyUnicodeUCS4_AsDefaultEncodedString(PyObject *, const(char)*);
alias _PyUnicodeUCS4_AsDefaultEncodedString _PyUnicode_AsDefaultEncodedString;


    const(char)*PyUnicodeUCS4_GetDefaultEncoding();
alias PyUnicodeUCS4_GetDefaultEncoding PyUnicode_GetDefaultEncoding;

    int PyUnicodeUCS4_SetDefaultEncoding(const(char)*encoding);
alias PyUnicodeUCS4_SetDefaultEncoding PyUnicode_SetDefaultEncoding;


    PyObject *PyUnicodeUCS4_Decode(const(char) *s, Py_ssize_t size, const(char) *encoding, const(char) *errors);
alias PyUnicodeUCS4_Decode PyUnicode_Decode;


    version(Python_3_2_Or_Later) {
    /** Decode a Unicode object unicode and return the result as Python
      object. */

    PyObject* PyUnicodeUCS4_AsDecodedObject(
            PyObject* unicode,          /* Unicode object */
            const(char)* encoding,       /* encoding */
            const(char)* errors          /* error handling */
            );
alias PyUnicodeUCS4_AsDecodedObject PyUnicode_AsDecodedObject;

    /** Decode a Unicode object unicode and return the result as Unicode
      object. */

    PyObject* PyUnicodeUCS4_AsDecodedUnicode(
            PyObject* unicode,          /* Unicode object */
            const(char)* encoding,       /* encoding */
            const(char)* errors          /* error handling */
            );
alias PyUnicodeUCS4_AsDecodedUnicode PyUnicode_AsDecodedUnicode;

    }

    PyObject *PyUnicodeUCS4_Encode(Py_UNICODE *s, Py_ssize_t size, const(char) *encoding, const(char) *errors);
alias PyUnicodeUCS4_Encode PyUnicode_Encode;

    PyObject *PyUnicodeUCS4_AsEncodedObject(PyObject *unicode, const(char) *encoding, const(char) *errors);
alias PyUnicodeUCS4_AsEncodedObject PyUnicode_AsEncodedObject;

    PyObject *PyUnicodeUCS4_AsEncodedString(PyObject *unicode, const(char) *encoding, const(char) *errors);
alias PyUnicodeUCS4_AsEncodedString PyUnicode_AsEncodedString;


    version(Python_3_2_Or_Later) {
        /** Encodes a Unicode object and returns the result as Unicode
           object. */

        PyObject* PyUnicodeUCS4_AsEncodedUnicode(
                PyObject* unicode,          /* Unicode object */
                const(char)* encoding,       /* encoding */
                const(char)* errors          /* error handling */
                );
alias PyUnicodeUCS4_AsEncodedUnicode PyUnicode_AsEncodedUnicode;

    }

    PyObject *PyUnicodeUCS4_DecodeUTF7(const(char) *string, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS4_DecodeUTF7 PyUnicode_DecodeUTF7;

    PyObject *PyUnicodeUCS4_EncodeUTF7(Py_UNICODE *data, Py_ssize_t length,
        int encodeSetO, int encodeWhiteSpace, const(char) *errors
      );
alias PyUnicodeUCS4_EncodeUTF7 PyUnicode_EncodeUTF7;


    PyObject *PyUnicodeUCS4_DecodeUTF8(const(char) *string, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS4_DecodeUTF8 PyUnicode_DecodeUTF8;

    PyObject *PyUnicodeUCS4_DecodeUTF8Stateful(const(char) *string, Py_ssize_t length,
        const(char) *errors, Py_ssize_t *consumed
      );
alias PyUnicodeUCS4_DecodeUTF8Stateful PyUnicode_DecodeUTF8Stateful;

    PyObject *PyUnicodeUCS4_AsUTF8String(PyObject *unicode);
alias PyUnicodeUCS4_AsUTF8String PyUnicode_AsUTF8String;

    PyObject *PyUnicodeUCS4_EncodeUTF8(Py_UNICODE *data, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS4_EncodeUTF8 PyUnicode_EncodeUTF8;


    PyObject *PyUnicodeUCS4_DecodeUTF16(const(char) *string, Py_ssize_t length, const(char) *errors, int *byteorder);
alias PyUnicodeUCS4_DecodeUTF16 PyUnicode_DecodeUTF16;

    PyObject *PyUnicodeUCS4_DecodeUTF16Stateful(const(char) *string, Py_ssize_t length,
        const(char) *errors, int *byteorder, Py_ssize_t *consumed
      );
alias PyUnicodeUCS4_DecodeUTF16Stateful PyUnicode_DecodeUTF16Stateful;

    PyObject *PyUnicodeUCS4_AsUTF16String(PyObject *unicode);
alias PyUnicodeUCS4_AsUTF16String PyUnicode_AsUTF16String;

    PyObject *PyUnicodeUCS4_EncodeUTF16(Py_UNICODE *data, Py_ssize_t length,
        const(char) *errors, int byteorder
      );
alias PyUnicodeUCS4_EncodeUTF16 PyUnicode_EncodeUTF16;


    PyObject *PyUnicodeUCS4_DecodeUnicodeEscape(const(char) *string, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS4_DecodeUnicodeEscape PyUnicode_DecodeUnicodeEscape;

    PyObject *PyUnicodeUCS4_AsUnicodeEscapeString(PyObject *unicode);
alias PyUnicodeUCS4_AsUnicodeEscapeString PyUnicode_AsUnicodeEscapeString;

    PyObject *PyUnicodeUCS4_EncodeUnicodeEscape(Py_UNICODE *data, Py_ssize_t length);
alias PyUnicodeUCS4_EncodeUnicodeEscape PyUnicode_EncodeUnicodeEscape;

    PyObject *PyUnicodeUCS4_DecodeRawUnicodeEscape(const(char) *string, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS4_DecodeRawUnicodeEscape PyUnicode_DecodeRawUnicodeEscape;

    PyObject *PyUnicodeUCS4_AsRawUnicodeEscapeString(PyObject *unicode);
alias PyUnicodeUCS4_AsRawUnicodeEscapeString PyUnicode_AsRawUnicodeEscapeString;

    PyObject *PyUnicodeUCS4_EncodeRawUnicodeEscape(Py_UNICODE *data, Py_ssize_t length);
alias PyUnicodeUCS4_EncodeRawUnicodeEscape PyUnicode_EncodeRawUnicodeEscape;


    PyObject *_PyUnicodeUCS4_DecodeUnicodeInternal(const(char) *string, Py_ssize_t length, const(char) *errors);
alias _PyUnicodeUCS4_DecodeUnicodeInternal _PyUnicode_DecodeUnicodeInternal;


    PyObject *PyUnicodeUCS4_DecodeLatin1(const(char) *string, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS4_DecodeLatin1 PyUnicode_DecodeLatin1;

    PyObject *PyUnicodeUCS4_AsLatin1String(PyObject *unicode);
alias PyUnicodeUCS4_AsLatin1String PyUnicode_AsLatin1String;

    PyObject *PyUnicodeUCS4_EncodeLatin1(Py_UNICODE *data, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS4_EncodeLatin1 PyUnicode_EncodeLatin1;


    PyObject *PyUnicodeUCS4_DecodeASCII(const(char) *string, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS4_DecodeASCII PyUnicode_DecodeASCII;

    PyObject *PyUnicodeUCS4_AsASCIIString(PyObject *unicode);
alias PyUnicodeUCS4_AsASCIIString PyUnicode_AsASCIIString;

    PyObject *PyUnicodeUCS4_EncodeASCII(Py_UNICODE *data, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS4_EncodeASCII PyUnicode_EncodeASCII;


    PyObject *PyUnicodeUCS4_DecodeCharmap(const(char) *string, Py_ssize_t length,
        PyObject *mapping, const(char) *errors
      );
alias PyUnicodeUCS4_DecodeCharmap PyUnicode_DecodeCharmap;

    PyObject *PyUnicodeUCS4_AsCharmapString(PyObject *unicode, PyObject *mapping);
alias PyUnicodeUCS4_AsCharmapString PyUnicode_AsCharmapString;

    PyObject *PyUnicodeUCS4_EncodeCharmap(Py_UNICODE *data, Py_ssize_t length,
        PyObject *mapping, const(char) *errors
      );
alias PyUnicodeUCS4_EncodeCharmap PyUnicode_EncodeCharmap;

    PyObject *PyUnicodeUCS4_TranslateCharmap(Py_UNICODE *data, Py_ssize_t length,
        PyObject *table, const(char) *errors
      );
alias PyUnicodeUCS4_TranslateCharmap PyUnicode_TranslateCharmap;


    version (Windows) {
      PyObject *PyUnicodeUCS4_DecodeMBCS(const(char) *string, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS4_DecodeMBCS PyUnicode_DecodeMBCS;

      PyObject *PyUnicodeUCS4_AsMBCSString(PyObject *unicode);
alias PyUnicodeUCS4_AsMBCSString PyUnicode_AsMBCSString;

      PyObject *PyUnicodeUCS4_EncodeMBCS(Py_UNICODE *data, Py_ssize_t length, const(char) *errors);
alias PyUnicodeUCS4_EncodeMBCS PyUnicode_EncodeMBCS;

    }

    int PyUnicodeUCS4_EncodeDecimal(Py_UNICODE *s, Py_ssize_t length, char *output, const(char) *errors);
alias PyUnicodeUCS4_EncodeDecimal PyUnicode_EncodeDecimal;


    /** Concat two strings giving a new Unicode string. */
    PyObject *PyUnicodeUCS4_Concat(PyObject *left, PyObject *right);
alias PyUnicodeUCS4_Concat PyUnicode_Concat;


    version(Python_3_2_Or_Later) {
        /** Concat two strings and put the result in *pleft
           (sets *pleft to NULL on error) */

        void PyUnicodeUCS4_Append(
                PyObject** pleft,           /* Pointer to left string */
                PyObject* right             /* Right string */
                );
alias PyUnicodeUCS4_Append PyUnicode_Append;


        /** Concat two strings, put the result in *pleft and drop the right object
           (sets *pleft to NULL on error) */

        void PyUnicodeUCS4_AppendAndDel(
                PyObject** pleft,           /* Pointer to left string */
                PyObject* right             /* Right string */
                );
alias PyUnicodeUCS4_AppendAndDel PyUnicode_AppendAndDel;

    }

    /** Split a string giving a list of Unicode strings.

      If sep is NULL, splitting will be done at all whitespace
      substrings. Otherwise, splits occur at the given separator.

      At most maxsplit splits will be done. If negative, no limit is set.

      Separators are not included in the resulting list.

     */
    PyObject *PyUnicodeUCS4_Split(PyObject *s, PyObject *sep, Py_ssize_t maxsplit);
alias PyUnicodeUCS4_Split PyUnicode_Split;


    /** Ditto PyUnicode_Split, but split at line breaks.

       CRLF is considered to be one line break. Line breaks are not
       included in the resulting list. */
    PyObject *PyUnicodeUCS4_Splitlines(PyObject *s, int keepends);
alias PyUnicodeUCS4_Splitlines PyUnicode_Splitlines;

    version(Python_2_5_Or_Later) {
        /** Partition a string using a given separator. */

        PyObject* PyUnicodeUCS4_Partition(
                PyObject* s,                /* String to partition */
                PyObject* sep               /* String separator */
                );
alias PyUnicodeUCS4_Partition PyUnicode_Partition;


        /** Partition a string using a given separator, searching from the end of the
           string. */

        PyObject* PyUnicodeUCS4_RPartition(
                PyObject* s,                /* String to partition */
                PyObject* sep               /* String separator */
                );
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
    PyObject *PyUnicodeUCS4_RSplit(PyObject *s, PyObject *sep, Py_ssize_t maxsplit);
alias PyUnicodeUCS4_RSplit PyUnicode_RSplit;


    /** Translate a string by applying a character mapping table to it and
      return the resulting Unicode object.

      The mapping table must map Unicode ordinal integers to Unicode
      ordinal integers or None (causing deletion of the character).

      Mapping tables may be dictionaries or sequences. Unmapped character
      ordinals (ones which cause a LookupError) are left untouched and
      are copied as-is.

     */
    PyObject *PyUnicodeUCS4_Translate(PyObject *str, PyObject *table, const(char) *errors);
alias PyUnicodeUCS4_Translate PyUnicode_Translate;


    /** Join a sequence of strings using the given separator and return
      the resulting Unicode string. */
    PyObject *PyUnicodeUCS4_Join(PyObject *separator, PyObject *seq);
alias PyUnicodeUCS4_Join PyUnicode_Join;


    /** Return 1 if substr matches str[start:end] at the given tail end, 0
      otherwise. */
    Py_ssize_t PyUnicodeUCS4_Tailmatch(PyObject *str, PyObject *substr,
        Py_ssize_t start, Py_ssize_t end, int direction
      );
alias PyUnicodeUCS4_Tailmatch PyUnicode_Tailmatch;


    /** Return the first position of substr in str[start:end] using the
      given search direction or -1 if not found. -2 is returned in case
      an error occurred and an exception is set. */
    Py_ssize_t PyUnicodeUCS4_Find(
            PyObject *str, 
            PyObject *substr,
            Py_ssize_t start, 
            Py_ssize_t end, 
            int direction
      );
alias PyUnicodeUCS4_Find PyUnicode_Find;


    /** Count the number of occurrences of substr in str[start:end]. */
    Py_ssize_t PyUnicodeUCS4_Count(
            PyObject *str, 
            PyObject *substr, 
            Py_ssize_t start, 
            Py_ssize_t end);
alias PyUnicodeUCS4_Count PyUnicode_Count;


    /** Replace at most maxcount occurrences of substr in str with replstr
       and return the resulting Unicode object. */
    PyObject* PyUnicodeUCS4_Replace(
            PyObject *str, 
            PyObject *substr,
            PyObject *replstr, 
            Py_ssize_t maxcount
      );
alias PyUnicodeUCS4_Replace PyUnicode_Replace;


    /** Compare two strings and return -1, 0, 1 for less than, equal,
      greater than resp. */
    int PyUnicodeUCS4_Compare(PyObject *left, PyObject *right);
alias PyUnicodeUCS4_Compare PyUnicode_Compare;

    version(Python_3_2_Or_Later) {
        /** Compare two strings and return -1, 0, 1 for less than, equal,
          greater than resp. */
        int PyUnicodeUCS4_CompareWithASCIIString(
                PyObject* left,
                const(char)* right           /* ASCII-encoded string */
                );
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

        PyObject* PyUnicodeUCS4_RichCompare(
                PyObject* left,             /* Left string */
                PyObject* right,            /* Right string */
                int op                      /* Operation: Py_EQ, Py_NE, Py_GT, etc. */
                );
alias PyUnicodeUCS4_RichCompare PyUnicode_RichCompare;

    }

    /** Apply a argument tuple or dictionary to a format string and return
      the resulting Unicode string. */
    PyObject* PyUnicodeUCS4_Format(PyObject* format, PyObject* args);
alias PyUnicodeUCS4_Format PyUnicode_Format;


    /** Checks whether element is contained in container and return 1/0
       accordingly.

       element has to coerce to an one element Unicode string. -1 is
       returned in case of an error. */
    int PyUnicodeUCS4_Contains(PyObject* container, PyObject* element);
alias PyUnicodeUCS4_Contains PyUnicode_Contains;


    version(Python_3_2_Or_Later) {
        int PyUnicodeUCS4_IsIdentifier(PyObject* s);
alias PyUnicodeUCS4_IsIdentifier PyUnicode_IsIdentifier;

    }


    int _PyUnicodeUCS4_IsLowercase(Py_UNICODE ch);
alias _PyUnicodeUCS4_IsLowercase _PyUnicode_IsLowercase;

    int _PyUnicodeUCS4_IsUppercase(Py_UNICODE ch);
alias _PyUnicodeUCS4_IsUppercase _PyUnicode_IsUppercase;

    int _PyUnicodeUCS4_IsTitlecase(Py_UNICODE ch);
alias _PyUnicodeUCS4_IsTitlecase _PyUnicode_IsTitlecase;

    int _PyUnicodeUCS4_IsWhitespace(Py_UNICODE ch);
alias _PyUnicodeUCS4_IsWhitespace _PyUnicode_IsWhitespace;

    int _PyUnicodeUCS4_IsLinebreak(Py_UNICODE ch);
alias _PyUnicodeUCS4_IsLinebreak _PyUnicode_IsLinebreak;

    Py_UNICODE _PyUnicodeUCS4_ToLowercase(Py_UNICODE ch);
alias _PyUnicodeUCS4_ToLowercase _PyUnicode_ToLowercase;

    Py_UNICODE _PyUnicodeUCS4_ToUppercase(Py_UNICODE ch);
alias _PyUnicodeUCS4_ToUppercase _PyUnicode_ToUppercase;

    Py_UNICODE _PyUnicodeUCS4_ToTitlecase(Py_UNICODE ch);
alias _PyUnicodeUCS4_ToTitlecase _PyUnicode_ToTitlecase;

    int _PyUnicodeUCS4_ToDecimalDigit(Py_UNICODE ch);
alias _PyUnicodeUCS4_ToDecimalDigit _PyUnicode_ToDecimalDigit;

    int _PyUnicodeUCS4_ToDigit(Py_UNICODE ch);
alias _PyUnicodeUCS4_ToDigit _PyUnicode_ToDigit;

    double _PyUnicodeUCS4_ToNumeric(Py_UNICODE ch);
alias _PyUnicodeUCS4_ToNumeric _PyUnicode_ToNumeric;

    int _PyUnicodeUCS4_IsDecimalDigit(Py_UNICODE ch);
alias _PyUnicodeUCS4_IsDecimalDigit _PyUnicode_IsDecimalDigit;

    int _PyUnicodeUCS4_IsDigit(Py_UNICODE ch);
alias _PyUnicodeUCS4_IsDigit _PyUnicode_IsDigit;

    int _PyUnicodeUCS4_IsNumeric(Py_UNICODE ch);
alias _PyUnicodeUCS4_IsNumeric _PyUnicode_IsNumeric;

    int _PyUnicodeUCS4_IsAlpha(Py_UNICODE ch);
alias _PyUnicodeUCS4_IsAlpha _PyUnicode_IsAlpha;

}
version(Python_3_2_Or_Later) {
    size_t Py_UNICODE_strlen(const(Py_UNICODE)* u);

    Py_UNICODE* Py_UNICODE_strcpy(Py_UNICODE* s1, const(Py_UNICODE)* s2);

    Py_UNICODE* Py_UNICODE_strcat(Py_UNICODE* s1, const(Py_UNICODE)* s2);

    Py_UNICODE* Py_UNICODE_strncpy(
            Py_UNICODE* s1,
            const(Py_UNICODE)* s2,
            size_t n);

    int Py_UNICODE_strcmp(
            const(Py_UNICODE)* s1,
            const(Py_UNICODE)* s2
            );

    int Py_UNICODE_strncmp(
            const(Py_UNICODE)* s1,
            const(Py_UNICODE)* s2,
            size_t n
            );

    Py_UNICODE* Py_UNICODE_strchr(
            const(Py_UNICODE)* s,
            Py_UNICODE c
            );

    Py_UNICODE* Py_UNICODE_strrchr(
            const(Py_UNICODE)* s,
            Py_UNICODE c
            );

    /* Create a copy of a unicode string ending with a nul character. Return NULL
       and raise a MemoryError exception on memory allocation failure, otherwise
       return a new allocated buffer (use PyMem_Free() to free the buffer). */

    Py_UNICODE* PyUnicode_AsUnicodeCopy(
            PyObject* unicode
            );
}


int _PyUnicode_IsTitlecase(
    Py_UCS4 ch       /* Unicode character */
    );

int _PyUnicode_IsXidStart(
    Py_UCS4 ch       /* Unicode character */
    );
/** Externally visible for str.strip(unicode) */
PyObject* _PyUnicode_XStrip(PyUnicodeObject* self, int striptype,
        PyObject *sepobj
        );
version(Python_3_2_Or_Later) {
    /** Using the current locale, insert the thousands grouping
      into the string pointed to by buffer.  For the argument descriptions,
      see Objects/stringlib/localeutil.h */
    Py_ssize_t _PyUnicode_InsertThousandsGroupingLocale(
            Py_UNICODE* buffer,
            Py_ssize_t n_buffer,
            Py_UNICODE* digits,
            Py_ssize_t n_digits,
            Py_ssize_t min_width);

    /** Using explicit passed-in values, insert the thousands grouping
      into the string pointed to by buffer.  For the argument descriptions,
      see Objects/stringlib/localeutil.h */
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
    PyObject* PyUnicode_TransformDecimalToASCII(
            Py_UNICODE *s,              /* Unicode buffer */
            Py_ssize_t length           /* Number of Py_UNICODE chars to transform */
            );
    /* --- File system encoding ---------------------------------------------- */

    /** ParseTuple converter: encode str objects to bytes using
      PyUnicode_EncodeFSDefault(); bytes objects are output as-is. */

    int PyUnicode_FSConverter(PyObject*, void*);

    /** ParseTuple converter: decode bytes objects to unicode using
      PyUnicode_DecodeFSDefaultAndSize(); str objects are output as-is. */

    int PyUnicode_FSDecoder(PyObject*, void*);

    /** Decode a null-terminated string using Py_FileSystemDefaultEncoding
      and the "surrogateescape" error handler.

      If Py_FileSystemDefaultEncoding is not set, fall back to the locale
      encoding.

      Use PyUnicode_DecodeFSDefaultAndSize() if the string length is known.
     */

    PyObject* PyUnicode_DecodeFSDefault(
            const(char)* s               /* encoded string */
            );

    /** Decode a string using Py_FileSystemDefaultEncoding
      and the "surrogateescape" error handler.

      If Py_FileSystemDefaultEncoding is not set, fall back to the locale
      encoding.
     */

    PyObject* PyUnicode_DecodeFSDefaultAndSize(
            const(char)* s,               /* encoded string */
            Py_ssize_t size              /* size */
            );

    /* Encode a Unicode object to Py_FileSystemDefaultEncoding with the
       "surrogateescape" error handler, and return bytes.

       If Py_FileSystemDefaultEncoding is not set, fall back to the locale
       encoding.
     */

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

int Py_UNICODE_ISALNUM()(Py_UNICODE ch) {
    return (
            Py_UNICODE_ISALPHA(ch)
            || Py_UNICODE_ISDECIMAL(ch)
            || Py_UNICODE_ISDIGIT(ch)
            || Py_UNICODE_ISNUMERIC(ch)
           );
}

void Py_UNICODE_COPY()(void* target, void* source, size_t length) {
    memcpy(target, source, cast(uint)(length* Py_UNICODE.sizeof));
}

void Py_UNICODE_FILL()(Py_UNICODE* target, Py_UNICODE value, size_t length) {
    for (size_t i = 0; i < length; i++) {
        target[i] = value;
    }
}

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


