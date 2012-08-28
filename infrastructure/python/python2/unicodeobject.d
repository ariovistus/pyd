module python2.unicodeobject;

import std.c.stdarg: va_list;
import std.c.string;
import python2.types;
import python2.object;

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

// EMN: waddawedohere? TODO: figure it out
version(Python_2_6_Or_Later) {
    /* Similar to PyUnicode_FromUnicode(), but u points to Latin-1 encoded bytes */
    PyObject* PyUnicode_FromStringAndSize(
            const(char)* u,       /* char buffer */
            Py_ssize_t size       /* size of buffer */
            );

    /* Similar to PyUnicode_FromUnicode(), but u points to null-terminated
       Latin-1 encoded bytes */
    PyObject* PyUnicode_FromString(
            const(char)* u       /* string */
            );
    PyObject* PyUnicode_FromFormatV(const(char)*, va_list);
    PyObject* PyUnicode_FromFormat(const(char)*, ...);

    /* Format the object based on the format_spec, as defined in PEP 3101
       (Advanced String Formatting). */
    PyObject* _PyUnicode_FormatAdvanced(PyObject* obj,
            Py_UNICODE* format_spec,
            Py_ssize_t format_spec_len);
    int PyUnicode_ClearFreeList();
    PyObject* PyUnicode_DecodeUTF7Stateful(
            const(char)* string,        /* UTF-7 encoded string */
            Py_ssize_t length,          /* size of string */
            const(char)* errors,        /* error handling */
            Py_ssize_t*  consumed       /* bytes consumed */
            );
    PyObject* PyUnicode_DecodeUTF32(
            const(char)* string,        /* UTF-32 encoded string */
            Py_ssize_t length,          /* size of string */
            const(char)* errors,        /* error handling */
            int* byteorder              /* pointer to byteorder to use
                                           0=native;-1=LE,1=BE; updated on
                                           exit */
            );

    PyObject* PyUnicode_DecodeUTF32Stateful(
            const(char)* string,        /* UTF-32 encoded string */
            Py_ssize_t length,          /* size of string */
            const(char)* errors,        /* error handling */
            int* byteorder,             /* pointer to byteorder to use
                                           0=native;-1=LE,1=BE; updated on
                                           exit */
            Py_ssize_t* consumed        /* bytes consumed */
            );
    /* Returns a Python string using the UTF-32 encoding in native byte
       order. The string always starts with a BOM mark.  */

    PyObject* PyUnicode_AsUTF32String(
            PyObject* unicode           /* Unicode object */
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
            const Py_UNICODE* data,     /* Unicode char buffer */
            Py_ssize_t length,          /* number of Py_UNICODE chars to encode */
            const(char)* errors,        /* error handling */
            int byteorder               /* byteorder to use 0=BOM+native;-1=LE,1=BE */
            );
}

// YYY: Unfortunately, we have to do it the tedious way since there's no
// preprocessor in D:
version (Python_Unicode_UCS2) {
    PyObject* PyUnicodeUCS2_FromUnicode(Py_UNICODE* u, Py_ssize_t size);
    Py_UNICODE* PyUnicodeUCS2_AsUnicode(PyObject* unicode);
    Py_ssize_t PyUnicodeUCS2_GetSize(PyObject* unicode);
    Py_UNICODE PyUnicodeUCS2_GetMax();

    int PyUnicodeUCS2_Resize(PyObject** unicode, Py_ssize_t length);
    PyObject* PyUnicodeUCS2_FromEncodedObject(PyObject* obj, const(char)* encoding, const(char)* errors);
    PyObject* PyUnicodeUCS2_FromObject(PyObject* obj);

    PyObject* PyUnicodeUCS2_FromWideChar(const(wchar)* w, Py_ssize_t size);
    Py_ssize_t PyUnicodeUCS2_AsWideChar(PyUnicodeObject* unicode, const(wchar)* w, Py_ssize_t size);

    PyObject* PyUnicodeUCS2_FromOrdinal(int ordinal);

    PyObject* _PyUnicodeUCS2_AsDefaultEncodedString(PyObject*, const(char)*);

    const(char)*PyUnicodeUCS2_GetDefaultEncoding();
    int PyUnicodeUCS2_SetDefaultEncoding(const(char)*encoding);

    PyObject* PyUnicodeUCS2_Decode(const(char)* s, Py_ssize_t size, const(char)* encoding, const(char)* errors);
    PyObject* PyUnicodeUCS2_Encode(Py_UNICODE* s, Py_ssize_t size, const(char)* encoding, const(char)* errors);
    PyObject* PyUnicodeUCS2_AsEncodedObject(PyObject* unicode, const(char)* encoding, const(char)* errors);
    PyObject* PyUnicodeUCS2_AsEncodedString(PyObject* unicode, const(char)* encoding, const(char)* errors);

    PyObject* PyUnicodeUCS2_DecodeUTF7(const(char)* string, Py_ssize_t length, const(char)* errors);
    PyObject* PyUnicodeUCS2_EncodeUTF7(Py_UNICODE* data, Py_ssize_t length,
            int encodeSetO, int encodeWhiteSpace, const(char)* errors
            );

    PyObject* PyUnicodeUCS2_DecodeUTF8(const(char)* string, Py_ssize_t length, const(char)* errors);
    PyObject* PyUnicodeUCS2_DecodeUTF8Stateful(const(char)* string, Py_ssize_t length,
            const(char)* errors, Py_ssize_t* consumed
            );
    PyObject* PyUnicodeUCS2_AsUTF8String(PyObject* unicode);
    PyObject* PyUnicodeUCS2_EncodeUTF8(Py_UNICODE* data, Py_ssize_t length, const(char)* errors);

    PyObject* PyUnicodeUCS2_DecodeUTF16(const(char)* string, Py_ssize_t length, const(char)* errors, int* byteorder);
    PyObject* PyUnicodeUCS2_DecodeUTF16Stateful(const(char)* string, Py_ssize_t length,
            const(char)* errors, int *byteorder, Py_ssize_t* consumed
            );
    PyObject* PyUnicodeUCS2_AsUTF16String(PyObject* unicode);
    PyObject* PyUnicodeUCS2_EncodeUTF16(Py_UNICODE* data, Py_ssize_t length,
            const(char)* errors, int byteorder
            );

    PyObject* PyUnicodeUCS2_DecodeUnicodeEscape(const(char)* string, Py_ssize_t length, const(char)* errors);
    PyObject* PyUnicodeUCS2_AsUnicodeEscapeString(PyObject* unicode);
    PyObject* PyUnicodeUCS2_EncodeUnicodeEscape(Py_UNICODE* data, Py_ssize_t length);
    PyObject* PyUnicodeUCS2_DecodeRawUnicodeEscape(const(char)* string, Py_ssize_t length, const(char)* errors);
    PyObject* PyUnicodeUCS2_AsRawUnicodeEscapeString(PyObject* unicode);
    PyObject* PyUnicodeUCS2_EncodeRawUnicodeEscape(Py_UNICODE* data, Py_ssize_t length);

    PyObject* _PyUnicodeUCS2_DecodeUnicodeInternal(const(char)* string, Py_ssize_t length, const(char)* errors);

    PyObject* PyUnicodeUCS2_DecodeLatin1(const(char)* string, Py_ssize_t length, const(char)* errors);
    PyObject* PyUnicodeUCS2_AsLatin1String(PyObject* unicode);
    PyObject* PyUnicodeUCS2_EncodeLatin1(Py_UNICODE* data, Py_ssize_t length, const(char)* errors);

    PyObject* PyUnicodeUCS2_DecodeASCII(const(char)* string, Py_ssize_t length, const(char)* errors);
    PyObject* PyUnicodeUCS2_AsASCIIString(PyObject* unicode);
    PyObject* PyUnicodeUCS2_EncodeASCII(Py_UNICODE* data, Py_ssize_t length, const(char)* errors);

    PyObject* PyUnicodeUCS2_DecodeCharmap(const(char)* string, Py_ssize_t length,
            PyObject* mapping, const(char)* errors
            );
    PyObject* PyUnicodeUCS2_AsCharmapString(PyObject* unicode, PyObject* mapping);
    PyObject* PyUnicodeUCS2_EncodeCharmap(Py_UNICODE* data, Py_ssize_t length,
            PyObject* mapping, const(char)* errors
            );
    PyObject* PyUnicodeUCS2_TranslateCharmap(Py_UNICODE* data, Py_ssize_t length,
            PyObject* table, const(char)* errors
            );

    version (Windows) {
        PyObject* PyUnicodeUCS2_DecodeMBCS(const(char)* string, Py_ssize_t length, const(char)* errors);
        PyObject* PyUnicodeUCS2_AsMBCSString(PyObject* unicode);
        PyObject* PyUnicodeUCS2_EncodeMBCS(Py_UNICODE* data, Py_ssize_t length, const(char)* errors);
    }

    int PyUnicodeUCS2_EncodeDecimal(Py_UNICODE* s, Py_ssize_t length, char* output, const(char)* errors);

    PyObject* PyUnicodeUCS2_Concat(PyObject* left, PyObject* right);
    PyObject* PyUnicodeUCS2_Split(PyObject* s, PyObject* sep, Py_ssize_t maxsplit);
    PyObject* PyUnicodeUCS2_Splitlines(PyObject* s, int keepends);
    version(Python_2_5_Or_Later){
        PyObject* PyUnicodeUCS2_Partition(PyObject* s, PyObject* sep);
        PyObject* PyUnicodeUCS2_RPartition(PyObject* s, PyObject* sep);
    }
    PyObject* PyUnicodeUCS2_RSplit(PyObject* s, PyObject* sep, Py_ssize_t maxsplit);
    PyObject* PyUnicodeUCS2_Translate(PyObject* str, PyObject* table, const(char)* errors);
    PyObject* PyUnicodeUCS2_Join(PyObject* separator, PyObject* seq);
    Py_ssize_t PyUnicodeUCS2_Tailmatch(PyObject* str, PyObject* substr,
            Py_ssize_t start, Py_ssize_t end, int direction
            );
    Py_ssize_t PyUnicodeUCS2_Find(PyObject* str, PyObject* substr,
            Py_ssize_t start, Py_ssize_t end, int direction
            );
    Py_ssize_t PyUnicodeUCS2_Count(PyObject* str, PyObject* substr, Py_ssize_t start, Py_ssize_t end);
    PyObject* PyUnicodeUCS2_Replace(PyObject* str, PyObject* substr,
            PyObject* replstr, Py_ssize_t maxcount
            );
    int PyUnicodeUCS2_Compare(PyObject* left, PyObject* right);
    PyObject* PyUnicodeUCS2_Format(PyObject* format, PyObject* args);
    int PyUnicodeUCS2_Contains(PyObject* container, PyObject* element);
    PyObject* _PyUnicodeUCS2_XStrip(PyUnicodeObject* self, int striptype,
            PyObject* sepobj
            );

    int _PyUnicodeUCS2_IsLowercase(Py_UNICODE ch);
    int _PyUnicodeUCS2_IsUppercase(Py_UNICODE ch);
    int _PyUnicodeUCS2_IsTitlecase(Py_UNICODE ch);
    int _PyUnicodeUCS2_IsWhitespace(Py_UNICODE ch);
    int _PyUnicodeUCS2_IsLinebreak(Py_UNICODE ch);
    Py_UNICODE _PyUnicodeUCS2_ToLowercase(Py_UNICODE ch);
    Py_UNICODE _PyUnicodeUCS2_ToUppercase(Py_UNICODE ch);
    Py_UNICODE _PyUnicodeUCS2_ToTitlecase(Py_UNICODE ch);
    int _PyUnicodeUCS2_ToDecimalDigit(Py_UNICODE ch);
    int _PyUnicodeUCS2_ToDigit(Py_UNICODE ch);
    double _PyUnicodeUCS2_ToNumeric(Py_UNICODE ch);
    int _PyUnicodeUCS2_IsDecimalDigit(Py_UNICODE ch);
    int _PyUnicodeUCS2_IsDigit(Py_UNICODE ch);
    int _PyUnicodeUCS2_IsNumeric(Py_UNICODE ch);
    int _PyUnicodeUCS2_IsAlpha(Py_UNICODE ch);

} else { /* not Python_Unicode_UCS2: */

    PyObject* PyUnicodeUCS4_FromUnicode(Py_UNICODE* u, Py_ssize_t size);
    Py_UNICODE* PyUnicodeUCS4_AsUnicode(PyObject* unicode);
    Py_ssize_t PyUnicodeUCS4_GetSize(PyObject* unicode);
    Py_UNICODE PyUnicodeUCS4_GetMax();

    int PyUnicodeUCS4_Resize(PyObject** unicode, Py_ssize_t length);
    PyObject* PyUnicodeUCS4_FromEncodedObject(PyObject* obj, const(char)* encoding, const(char)* errors);
    PyObject* PyUnicodeUCS4_FromObject(PyObject* obj);

    PyObject* PyUnicodeUCS4_FromWideChar(const(wchar)* w, Py_ssize_t size);
    Py_ssize_t PyUnicodeUCS4_AsWideChar(PyUnicodeObject* unicode, const(wchar)* w, Py_ssize_t size);

    PyObject* PyUnicodeUCS4_FromOrdinal(int ordinal);

    PyObject* _PyUnicodeUCS4_AsDefaultEncodedString(PyObject*, const(char)* );

    const(char)* PyUnicodeUCS4_GetDefaultEncoding();
    int PyUnicodeUCS4_SetDefaultEncoding(const(char)* encoding);

    PyObject* PyUnicodeUCS4_Decode(const(char)* s, Py_ssize_t size, const(char)* encoding, const(char)* errors);
    PyObject* PyUnicodeUCS4_Encode(Py_UNICODE* s, Py_ssize_t size, const(char)* encoding, const(char)* errors);
    PyObject* PyUnicodeUCS4_AsEncodedObject(PyObject* unicode, const(char)* encoding, const(char)* errors);
    PyObject* PyUnicodeUCS4_AsEncodedString(PyObject* unicode, const(char)* encoding, const(char)* errors);

    PyObject* PyUnicodeUCS4_DecodeUTF7(const(char)* string, Py_ssize_t length, const(char)* errors);
    PyObject* PyUnicodeUCS4_EncodeUTF7(Py_UNICODE* data, Py_ssize_t length,
            int encodeSetO, int encodeWhiteSpace, const(char)* errors
            );

    PyObject* PyUnicodeUCS4_DecodeUTF8(const(char)* string, Py_ssize_t length, const(char)* errors);
    PyObject* PyUnicodeUCS4_DecodeUTF8Stateful(const(char)* string, Py_ssize_t length,
            const(char)* errors, Py_ssize_t* consumed
            );
    PyObject* PyUnicodeUCS4_AsUTF8String(PyObject* unicode);
    PyObject* PyUnicodeUCS4_EncodeUTF8(Py_UNICODE* data, Py_ssize_t length, const(char)* errors);

    PyObject* PyUnicodeUCS4_DecodeUTF16(const(char)* string, Py_ssize_t length, const(char)* errors, int* byteorder);
    PyObject* PyUnicodeUCS4_DecodeUTF16Stateful(const(char)* string, Py_ssize_t length,
            const(char)* errors, int* byteorder, Py_ssize_t* consumed
            );
    PyObject* PyUnicodeUCS4_AsUTF16String(PyObject* unicode);
    PyObject* PyUnicodeUCS4_EncodeUTF16(Py_UNICODE* data, Py_ssize_t length,
            const(char)* errors, int byteorder
            );

    PyObject* PyUnicodeUCS4_DecodeUnicodeEscape(const(char)* string, Py_ssize_t length, const(char)* errors);
    PyObject* PyUnicodeUCS4_AsUnicodeEscapeString(PyObject* unicode);
    PyObject* PyUnicodeUCS4_EncodeUnicodeEscape(Py_UNICODE* data, Py_ssize_t length);
    PyObject* PyUnicodeUCS4_DecodeRawUnicodeEscape(const(char)* string, Py_ssize_t length, const(char)* errors);
    PyObject* PyUnicodeUCS4_AsRawUnicodeEscapeString(PyObject* unicode);
    PyObject* PyUnicodeUCS4_EncodeRawUnicodeEscape(Py_UNICODE* data, Py_ssize_t length);

    PyObject* _PyUnicodeUCS4_DecodeUnicodeInternal(const(char)* string, Py_ssize_t length, const(char)* errors);

    PyObject* PyUnicodeUCS4_DecodeLatin1(const(char)* string, Py_ssize_t length, const(char)* errors);
    PyObject* PyUnicodeUCS4_AsLatin1String(PyObject* unicode);
    PyObject* PyUnicodeUCS4_EncodeLatin1(Py_UNICODE* data, Py_ssize_t length, const(char)* errors);

    PyObject* PyUnicodeUCS4_DecodeASCII(const(char)* string, Py_ssize_t length, const(char)* errors);
    PyObject* PyUnicodeUCS4_AsASCIIString(PyObject* unicode);
    PyObject* PyUnicodeUCS4_EncodeASCII(Py_UNICODE* data, Py_ssize_t length, const(char)* errors);

    PyObject* PyUnicodeUCS4_DecodeCharmap(const(char)* string, Py_ssize_t length,
            PyObject* mapping, const(char)* errors
            );
    PyObject* PyUnicodeUCS4_AsCharmapString(PyObject* unicode, PyObject* mapping);
    PyObject* PyUnicodeUCS4_EncodeCharmap(Py_UNICODE* data, Py_ssize_t length,
            PyObject* mapping, const(char)* errors
            );
    PyObject* PyUnicodeUCS4_TranslateCharmap(Py_UNICODE* data, Py_ssize_t length,
            PyObject* table, const(char)* errors
            );

    version (Windows) {
        PyObject* PyUnicodeUCS4_DecodeMBCS(const(char)* string, Py_ssize_t length, const(char)* errors);
        PyObject* PyUnicodeUCS4_AsMBCSString(PyObject* unicode);
        PyObject* PyUnicodeUCS4_EncodeMBCS(Py_UNICODE* data, Py_ssize_t length, const(char)* errors);
    }

    int PyUnicodeUCS4_EncodeDecimal(Py_UNICODE* s, Py_ssize_t length, char* output, const(char)* errors);

    PyObject* PyUnicodeUCS4_Concat(PyObject* left, PyObject* right);
    PyObject* PyUnicodeUCS4_Split(PyObject* s, PyObject* sep, Py_ssize_t maxsplit);
    PyObject* PyUnicodeUCS4_Splitlines(PyObject* s, int keepends);
    version(Python_2_5_Or_Later){
        PyObject* PyUnicodeUCS4_Partition(PyObject* s, PyObject* sep);
        PyObject* PyUnicodeUCS4_RPartition(PyObject* s, PyObject* sep);
    }
    PyObject* PyUnicodeUCS4_RSplit(PyObject* s, PyObject* sep, Py_ssize_t maxsplit);
    PyObject* PyUnicodeUCS4_Translate(PyObject* str, PyObject* table, const(char)* errors);
    PyObject* PyUnicodeUCS4_Join(PyObject* separator, PyObject* seq);
    Py_ssize_t PyUnicodeUCS4_Tailmatch(PyObject* str, PyObject* substr,
            Py_ssize_t start, Py_ssize_t end, int direction
            );
    Py_ssize_t PyUnicodeUCS4_Find(PyObject* str, PyObject* substr,
            Py_ssize_t start, Py_ssize_t end, int direction
            );
    Py_ssize_t PyUnicodeUCS4_Count(PyObject* str, PyObject* substr, Py_ssize_t start, Py_ssize_t end);
    PyObject* PyUnicodeUCS4_Replace(PyObject* str, PyObject* substr,
            PyObject* replstr, Py_ssize_t maxcount
            );
    int PyUnicodeUCS4_Compare(PyObject* left, PyObject* right);
    PyObject* PyUnicodeUCS4_Format(PyObject* format, PyObject* args);
    int PyUnicodeUCS4_Contains(PyObject* container, PyObject* element);
    PyObject* _PyUnicodeUCS4_XStrip(PyUnicodeObject* self, int striptype,
            PyObject* sepobj
            );

    int _PyUnicodeUCS4_IsLowercase(Py_UNICODE ch);
    int _PyUnicodeUCS4_IsUppercase(Py_UNICODE ch);
    int _PyUnicodeUCS4_IsTitlecase(Py_UNICODE ch);
    int _PyUnicodeUCS4_IsWhitespace(Py_UNICODE ch);
    int _PyUnicodeUCS4_IsLinebreak(Py_UNICODE ch);
    Py_UNICODE _PyUnicodeUCS4_ToLowercase(Py_UNICODE ch);
    Py_UNICODE _PyUnicodeUCS4_ToUppercase(Py_UNICODE ch);
    Py_UNICODE _PyUnicodeUCS4_ToTitlecase(Py_UNICODE ch);
    int _PyUnicodeUCS4_ToDecimalDigit(Py_UNICODE ch);
    int _PyUnicodeUCS4_ToDigit(Py_UNICODE ch);
    double _PyUnicodeUCS4_ToNumeric(Py_UNICODE ch);
    int _PyUnicodeUCS4_IsDecimalDigit(Py_UNICODE ch);
    int _PyUnicodeUCS4_IsDigit(Py_UNICODE ch);
    int _PyUnicodeUCS4_IsNumeric(Py_UNICODE ch);
    int _PyUnicodeUCS4_IsAlpha(Py_UNICODE ch);
}


/* The client programmer should call PyUnicode_XYZ, but linkage should be
 * done via either PyUnicodeUCS2_XYZ or PyUnicodeUCS4_XYZ. */
version (Python_Unicode_UCS2) {
    alias PyUnicodeUCS2_AsASCIIString PyUnicode_AsASCIIString;
    alias PyUnicodeUCS2_AsCharmapString PyUnicode_AsCharmapString;
    alias PyUnicodeUCS2_AsEncodedObject PyUnicode_AsEncodedObject;
    alias PyUnicodeUCS2_AsEncodedString PyUnicode_AsEncodedString;
    alias PyUnicodeUCS2_AsLatin1String PyUnicode_AsLatin1String;
    alias PyUnicodeUCS2_AsRawUnicodeEscapeString PyUnicode_AsRawUnicodeEscapeString;
    alias PyUnicodeUCS2_AsUTF16String PyUnicode_AsUTF16String;
    alias PyUnicodeUCS2_AsUTF8String PyUnicode_AsUTF8String;
    alias PyUnicodeUCS2_AsUnicode PyUnicode_AsUnicode;
    alias PyUnicodeUCS2_AsUnicodeEscapeString PyUnicode_AsUnicodeEscapeString;
    alias PyUnicodeUCS2_AsWideChar PyUnicode_AsWideChar;
    alias PyUnicodeUCS2_Compare PyUnicode_Compare;
    alias PyUnicodeUCS2_Concat PyUnicode_Concat;
    alias PyUnicodeUCS2_Contains PyUnicode_Contains;
    alias PyUnicodeUCS2_Count PyUnicode_Count;
    alias PyUnicodeUCS2_Decode PyUnicode_Decode;
    alias PyUnicodeUCS2_DecodeASCII PyUnicode_DecodeASCII;
    alias PyUnicodeUCS2_DecodeCharmap PyUnicode_DecodeCharmap;
    alias PyUnicodeUCS2_DecodeLatin1 PyUnicode_DecodeLatin1;
    alias PyUnicodeUCS2_DecodeRawUnicodeEscape PyUnicode_DecodeRawUnicodeEscape;
    alias PyUnicodeUCS2_DecodeUTF16 PyUnicode_DecodeUTF16;
    alias PyUnicodeUCS2_DecodeUTF16Stateful PyUnicode_DecodeUTF16Stateful;
    alias PyUnicodeUCS2_DecodeUTF8 PyUnicode_DecodeUTF8;
    alias PyUnicodeUCS2_DecodeUTF8Stateful PyUnicode_DecodeUTF8Stateful;
    alias PyUnicodeUCS2_DecodeUnicodeEscape PyUnicode_DecodeUnicodeEscape;
    alias PyUnicodeUCS2_Encode PyUnicode_Encode;
    alias PyUnicodeUCS2_EncodeASCII PyUnicode_EncodeASCII;
    alias PyUnicodeUCS2_EncodeCharmap PyUnicode_EncodeCharmap;
    alias PyUnicodeUCS2_EncodeDecimal PyUnicode_EncodeDecimal;
    alias PyUnicodeUCS2_EncodeLatin1 PyUnicode_EncodeLatin1;
    alias PyUnicodeUCS2_EncodeRawUnicodeEscape PyUnicode_EncodeRawUnicodeEscape;
    alias PyUnicodeUCS2_EncodeUTF16 PyUnicode_EncodeUTF16;
    alias PyUnicodeUCS2_EncodeUTF8 PyUnicode_EncodeUTF8;
    alias PyUnicodeUCS2_EncodeUnicodeEscape PyUnicode_EncodeUnicodeEscape;
    alias PyUnicodeUCS2_Find PyUnicode_Find;
    alias PyUnicodeUCS2_Format PyUnicode_Format;
    alias PyUnicodeUCS2_FromEncodedObject PyUnicode_FromEncodedObject;
    alias PyUnicodeUCS2_FromObject PyUnicode_FromObject;
    alias PyUnicodeUCS2_FromOrdinal PyUnicode_FromOrdinal;
    alias PyUnicodeUCS2_FromUnicode PyUnicode_FromUnicode;
    alias PyUnicodeUCS2_FromWideChar PyUnicode_FromWideChar;
    alias PyUnicodeUCS2_GetDefaultEncoding PyUnicode_GetDefaultEncoding;
    alias PyUnicodeUCS2_GetMax PyUnicode_GetMax;
    alias PyUnicodeUCS2_GetSize PyUnicode_GetSize;
    alias PyUnicodeUCS2_Join PyUnicode_Join;
    version(Python_2_5_Or_Later){
        alias PyUnicodeUCS2_Partition PyUnicode_Partition;
        alias PyUnicodeUCS2_Replace PyUnicode_Replace;
    }
    alias PyUnicodeUCS2_Resize PyUnicode_Resize;
    alias PyUnicodeUCS2_SetDefaultEncoding PyUnicode_SetDefaultEncoding;
    alias PyUnicodeUCS2_Split PyUnicode_Split;
    alias PyUnicodeUCS2_RPartition PyUnicode_RPartition;
    alias PyUnicodeUCS2_RSplit PyUnicode_RSplit;
    alias PyUnicodeUCS2_Splitlines PyUnicode_Splitlines;
    alias PyUnicodeUCS2_Tailmatch PyUnicode_Tailmatch;
    alias PyUnicodeUCS2_Translate PyUnicode_Translate;
    alias PyUnicodeUCS2_TranslateCharmap PyUnicode_TranslateCharmap;
    alias _PyUnicodeUCS2_AsDefaultEncodedString _PyUnicode_AsDefaultEncodedString;
    // omitted _PyUnicode_Fini
    // omitted _PyUnicode_Init
    alias _PyUnicodeUCS2_IsAlpha _PyUnicode_IsAlpha;
    alias _PyUnicodeUCS2_IsDecimalDigit _PyUnicode_IsDecimalDigit;
    alias _PyUnicodeUCS2_IsDigit _PyUnicode_IsDigit;
    alias _PyUnicodeUCS2_IsLinebreak _PyUnicode_IsLinebreak;
    alias _PyUnicodeUCS2_IsLowercase _PyUnicode_IsLowercase;
    alias _PyUnicodeUCS2_IsNumeric _PyUnicode_IsNumeric;
    alias _PyUnicodeUCS2_IsTitlecase _PyUnicode_IsTitlecase;
    alias _PyUnicodeUCS2_IsUppercase _PyUnicode_IsUppercase;
    alias _PyUnicodeUCS2_IsWhitespace _PyUnicode_IsWhitespace;
    alias _PyUnicodeUCS2_ToDecimalDigit _PyUnicode_ToDecimalDigit;
    alias _PyUnicodeUCS2_ToDigit _PyUnicode_ToDigit;
    alias _PyUnicodeUCS2_ToLowercase _PyUnicode_ToLowercase;
    alias _PyUnicodeUCS2_ToNumeric _PyUnicode_ToNumeric;
    alias _PyUnicodeUCS2_ToTitlecase _PyUnicode_ToTitlecase;
    alias _PyUnicodeUCS2_ToUppercase _PyUnicode_ToUppercase;
} else {
    alias PyUnicodeUCS4_AsASCIIString PyUnicode_AsASCIIString;
    alias PyUnicodeUCS4_AsCharmapString PyUnicode_AsCharmapString;
    alias PyUnicodeUCS4_AsEncodedObject PyUnicode_AsEncodedObject;
    alias PyUnicodeUCS4_AsEncodedString PyUnicode_AsEncodedString;
    alias PyUnicodeUCS4_AsLatin1String PyUnicode_AsLatin1String;
    alias PyUnicodeUCS4_AsRawUnicodeEscapeString PyUnicode_AsRawUnicodeEscapeString;
    alias PyUnicodeUCS4_AsUTF16String PyUnicode_AsUTF16String;
    alias PyUnicodeUCS4_AsUTF8String PyUnicode_AsUTF8String;
    alias PyUnicodeUCS4_AsUnicode PyUnicode_AsUnicode;
    alias PyUnicodeUCS4_AsUnicodeEscapeString PyUnicode_AsUnicodeEscapeString;
    alias PyUnicodeUCS4_AsWideChar PyUnicode_AsWideChar;
    alias PyUnicodeUCS4_Compare PyUnicode_Compare;
    alias PyUnicodeUCS4_Concat PyUnicode_Concat;
    alias PyUnicodeUCS4_Contains PyUnicode_Contains;
    alias PyUnicodeUCS4_Count PyUnicode_Count;
    alias PyUnicodeUCS4_Decode PyUnicode_Decode;
    alias PyUnicodeUCS4_DecodeASCII PyUnicode_DecodeASCII;
    alias PyUnicodeUCS4_DecodeCharmap PyUnicode_DecodeCharmap;
    alias PyUnicodeUCS4_DecodeLatin1 PyUnicode_DecodeLatin1;
    alias PyUnicodeUCS4_DecodeRawUnicodeEscape PyUnicode_DecodeRawUnicodeEscape;
    alias PyUnicodeUCS4_DecodeUTF16 PyUnicode_DecodeUTF16;
    alias PyUnicodeUCS4_DecodeUTF16Stateful PyUnicode_DecodeUTF16Stateful;
    alias PyUnicodeUCS4_DecodeUTF8 PyUnicode_DecodeUTF8;
    alias PyUnicodeUCS4_DecodeUTF8Stateful PyUnicode_DecodeUTF8Stateful;
    alias PyUnicodeUCS4_DecodeUnicodeEscape PyUnicode_DecodeUnicodeEscape;
    alias PyUnicodeUCS4_Encode PyUnicode_Encode;
    alias PyUnicodeUCS4_EncodeASCII PyUnicode_EncodeASCII;
    alias PyUnicodeUCS4_EncodeCharmap PyUnicode_EncodeCharmap;
    alias PyUnicodeUCS4_EncodeDecimal PyUnicode_EncodeDecimal;
    alias PyUnicodeUCS4_EncodeLatin1 PyUnicode_EncodeLatin1;
    alias PyUnicodeUCS4_EncodeRawUnicodeEscape PyUnicode_EncodeRawUnicodeEscape;
    alias PyUnicodeUCS4_EncodeUTF16 PyUnicode_EncodeUTF16;
    alias PyUnicodeUCS4_EncodeUTF8 PyUnicode_EncodeUTF8;
    alias PyUnicodeUCS4_EncodeUnicodeEscape PyUnicode_EncodeUnicodeEscape;
    alias PyUnicodeUCS4_Find PyUnicode_Find;
    alias PyUnicodeUCS4_Format PyUnicode_Format;
    alias PyUnicodeUCS4_FromEncodedObject PyUnicode_FromEncodedObject;
    alias PyUnicodeUCS4_FromObject PyUnicode_FromObject;
    alias PyUnicodeUCS4_FromOrdinal PyUnicode_FromOrdinal;
    alias PyUnicodeUCS4_FromUnicode PyUnicode_FromUnicode;
    alias PyUnicodeUCS4_FromWideChar PyUnicode_FromWideChar;
    alias PyUnicodeUCS4_GetDefaultEncoding PyUnicode_GetDefaultEncoding;
    alias PyUnicodeUCS4_GetMax PyUnicode_GetMax;
    alias PyUnicodeUCS4_GetSize PyUnicode_GetSize;
    alias PyUnicodeUCS4_Join PyUnicode_Join;
    version(Python_2_5_Or_Later){
        alias PyUnicodeUCS4_Partition PyUnicode_Partition;
        alias PyUnicodeUCS4_RPartition PyUnicode_RPartition;
    }
    alias PyUnicodeUCS4_Replace PyUnicode_Replace;
    alias PyUnicodeUCS4_Resize PyUnicode_Resize;
    alias PyUnicodeUCS4_RSplit PyUnicode_RSplit;
    alias PyUnicodeUCS4_SetDefaultEncoding PyUnicode_SetDefaultEncoding;
    alias PyUnicodeUCS4_Split PyUnicode_Split;
    alias PyUnicodeUCS4_Splitlines PyUnicode_Splitlines;
    alias PyUnicodeUCS4_Tailmatch PyUnicode_Tailmatch;
    alias PyUnicodeUCS4_Translate PyUnicode_Translate;
    alias PyUnicodeUCS4_TranslateCharmap PyUnicode_TranslateCharmap;
    alias _PyUnicodeUCS4_AsDefaultEncodedString _PyUnicode_AsDefaultEncodedString;
    // omitted _PyUnicode_Fini
    // omitted _PyUnicode_Init
    alias _PyUnicodeUCS4_IsAlpha _PyUnicode_IsAlpha;
    alias _PyUnicodeUCS4_IsDecimalDigit _PyUnicode_IsDecimalDigit;
    alias _PyUnicodeUCS4_IsDigit _PyUnicode_IsDigit;
    alias _PyUnicodeUCS4_IsLinebreak _PyUnicode_IsLinebreak;
    alias _PyUnicodeUCS4_IsLowercase _PyUnicode_IsLowercase;
    alias _PyUnicodeUCS4_IsNumeric _PyUnicode_IsNumeric;
    alias _PyUnicodeUCS4_IsTitlecase _PyUnicode_IsTitlecase;
    alias _PyUnicodeUCS4_IsUppercase _PyUnicode_IsUppercase;
    alias _PyUnicodeUCS4_IsWhitespace _PyUnicode_IsWhitespace;
    alias _PyUnicodeUCS4_ToDecimalDigit _PyUnicode_ToDecimalDigit;
    alias _PyUnicodeUCS4_ToDigit _PyUnicode_ToDigit;
    alias _PyUnicodeUCS4_ToLowercase _PyUnicode_ToLowercase;
    alias _PyUnicodeUCS4_ToNumeric _PyUnicode_ToNumeric;
    alias _PyUnicodeUCS4_ToTitlecase _PyUnicode_ToTitlecase;
    alias _PyUnicodeUCS4_ToUppercase _PyUnicode_ToUppercase;
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


