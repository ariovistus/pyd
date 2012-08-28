module python2.pyerrors;

import std.c.stdarg;
import python2.types;
import python2.object;
import python2.unicodeobject;

extern(C):
// Python-header-file: Include/pyerrors.h:

version(Python_2_5_Or_Later) {
    /* Error objects */

    struct PyBaseExceptionObject {
        mixin PyObject_HEAD;
        PyObject* dict;
        PyObject* args;
        PyObject* message;
    }

    struct PySyntaxErrorObject {
        mixin PyObject_HEAD;
        PyObject* dict;
        PyObject* args;
        PyObject* message;
        PyObject* msg;
        PyObject* filename;
        PyObject* lineno;
        PyObject* offset;
        PyObject* text;
        PyObject* print_file_and_line;
    }

    struct PyUnicodeErrorObject {
        mixin PyObject_HEAD;
        PyObject* dict;
        PyObject* args;
        PyObject* message;
        PyObject* encoding;
        PyObject* object;
        version(Python_2_6_Or_Later){
            Py_ssize_t start;
            Py_ssize_t end;
        }else{
            PyObject* start;
            PyObject* end;
        }
        PyObject* reason;
    }

    struct PySystemExitObject {
        mixin PyObject_HEAD;
        PyObject* dict;
        PyObject* args;
        PyObject* message;
        PyObject* code;
    }

    struct PyEnvironmentErrorObject {
        mixin PyObject_HEAD;
        PyObject* dict;
        PyObject* args;
        PyObject* message;
        PyObject* myerrno;
        PyObject* strerror;
        PyObject* filename;
    }

    version(Windows) {
        struct PyWindowsErrorObject {
            mixin PyObject_HEAD;
            PyObject* dict;
            PyObject* args;
            PyObject* message;
            PyObject* myerrno;
            PyObject* strerror;
            PyObject* filename;
            PyObject* winerror;
        }
    }
}

void PyErr_SetNone(PyObject*);
void PyErr_SetObject(PyObject*, PyObject*);
void PyErr_SetString(PyObject*, const(char)*);
PyObject*  PyErr_Occurred();
void PyErr_Clear();
void PyErr_Fetch(PyObject**, PyObject**, PyObject**);
void PyErr_Restore(PyObject*, PyObject*, PyObject*);

int PyErr_GivenExceptionMatches(PyObject*, PyObject*);
int PyErr_ExceptionMatches(PyObject*);
void PyErr_NormalizeException(PyObject**, PyObject**, PyObject**);

// All predefined Python exception types are dealt with in the global
// variables section toward the end of this file.

int PyErr_BadArgument();
PyObject* PyErr_NoMemory();
PyObject* PyErr_SetFromErrno(PyObject*);
PyObject* PyErr_SetFromErrnoWithFilenameObject(PyObject*, PyObject*);
PyObject* PyErr_SetFromErrnoWithFilename(PyObject*, char*);
PyObject* PyErr_SetFromErrnoWithUnicodeFilename(PyObject*, Py_UNICODE*);

PyObject* PyErr_Format(PyObject*, const(char)*, ...);

version (Windows) {
    PyObject* PyErr_SetFromWindowsErrWithFilenameObject(int, const(char)*);
    PyObject* PyErr_SetFromWindowsErrWithFilename(int, const(char)*);
    PyObject* PyErr_SetFromWindowsErrWithUnicodeFilename(int, Py_UNICODE*);
    PyObject* PyErr_SetFromWindowsErr(int);
    PyObject* PyErr_SetExcFromWindowsErrWithFilenameObject(PyObject*, int, PyObject*);
    PyObject* PyErr_SetExcFromWindowsErrWithFilename(PyObject*, int, const(char)*);
    PyObject* PyErr_SetExcFromWindowsErrWithUnicodeFilename(PyObject*, int, Py_UNICODE*);
    PyObject* PyErr_SetExcFromWindowsErr(PyObject*, int);
}

// PyErr_BadInternalCall and friends purposely omitted.

PyObject* PyErr_NewException(char* name, PyObject* base, PyObject* dict);
void PyErr_WriteUnraisable(PyObject*);

version(Python_2_5_Or_Later){
    int PyErr_WarnEx(PyObject*, char*, Py_ssize_t);
}else{
    int PyErr_Warn(PyObject*, char*);
}
int PyErr_WarnExplicit(PyObject*, const(char)*, const(char)*, int, const(char)*, PyObject*);

int PyErr_CheckSignals();
void PyErr_SetInterrupt();

void PyErr_SyntaxLocation(const(char)*, int);
PyObject* PyErr_ProgramText(const(char)*, int);

/////////////////////////////////////////////////////////////////////////////
// UNICODE ENCODING ERROR HANDLING INTERFACE
/////////////////////////////////////////////////////////////////////////////
PyObject* PyUnicodeDecodeError_Create(const(char)*, const(char)*, Py_ssize_t, Py_ssize_t, Py_ssize_t, const(char)*);

PyObject* PyUnicodeEncodeError_Create(const(char)*, Py_UNICODE*, Py_ssize_t, Py_ssize_t, Py_ssize_t, const(char)*);

PyObject* PyUnicodeTranslateError_Create(Py_UNICODE*, Py_ssize_t, Py_ssize_t, Py_ssize_t, const(char)*);

PyObject* PyUnicodeEncodeError_GetEncoding(PyObject*);
PyObject* PyUnicodeDecodeError_GetEncoding(PyObject*);

PyObject* PyUnicodeEncodeError_GetObject(PyObject*);
PyObject* PyUnicodeDecodeError_GetObject(PyObject*);
PyObject* PyUnicodeTranslateError_GetObject(PyObject*);

int PyUnicodeEncodeError_GetStart(PyObject*, Py_ssize_t*);
int PyUnicodeDecodeError_GetStart(PyObject*, Py_ssize_t*);
int PyUnicodeTranslateError_GetStart(PyObject*, Py_ssize_t*);

int PyUnicodeEncodeError_SetStart(PyObject*, Py_ssize_t);
int PyUnicodeDecodeError_SetStart(PyObject*, Py_ssize_t);
int PyUnicodeTranslateError_SetStart(PyObject* , Py_ssize_t);

int PyUnicodeEncodeError_GetEnd(PyObject*, Py_ssize_t*);
int PyUnicodeDecodeError_GetEnd(PyObject*, Py_ssize_t*);
int PyUnicodeTranslateError_GetEnd(PyObject* , Py_ssize_t*);

int PyUnicodeEncodeError_SetEnd(PyObject*, Py_ssize_t);
int PyUnicodeDecodeError_SetEnd(PyObject*, Py_ssize_t);
int PyUnicodeTranslateError_SetEnd(PyObject*, Py_ssize_t);

PyObject* PyUnicodeEncodeError_GetReason(PyObject*);
PyObject* PyUnicodeDecodeError_GetReason(PyObject*);
PyObject* PyUnicodeTranslateError_GetReason(PyObject*);

int PyUnicodeEncodeError_SetReason(PyObject*, const(char)*);
int PyUnicodeDecodeError_SetReason(PyObject*, const(char)*);
int PyUnicodeTranslateError_SetReason(PyObject*, const(char)*);

int PyOS_snprintf(char* str, size_t size, const(char)* format, ...);
int PyOS_vsnprintf(char* str, size_t size, const(char)* format, va_list va);


