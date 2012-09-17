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

Py_UNICODE Py_UNICODE_REPLACEMENT_CHARACTER = 0xFFFD;

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

mixin(substitute_and_alias(unicode_funs));

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


