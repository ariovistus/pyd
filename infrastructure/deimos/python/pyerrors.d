module deimos.python.pyerrors;

import std.c.stdarg;
import deimos.python.pyport;
import deimos.python.object;
import deimos.python.unicodeobject;

extern(C):
// Python-header-file: Include/pyerrors.h:

version(Python_3_0_Or_Later) {
    mixin template PyException_HEAD() {
        mixin PyObject_HEAD; 
        PyObject* dict;
        PyObject* args; 
        PyObject* traceback;
        PyObject* context; 
        PyObject* cause;
    }
}else version(Python_2_5_Or_Later) {
    mixin template PyException_HEAD() {
        mixin PyObject_HEAD;
        PyObject* dict;
        PyObject* args;
        PyObject* message;
    }
}

version(Python_2_5_Or_Later) {
    /* Error objects */

    struct PyBaseExceptionObject {
        mixin PyException_HEAD;
    }

    struct PySyntaxErrorObject {
        mixin PyException_HEAD;
        PyObject* msg;
        PyObject* filename;
        PyObject* lineno;
        PyObject* offset;
        PyObject* text;
        PyObject* print_file_and_line;
    }

    struct PyUnicodeErrorObject {
        mixin PyException_HEAD;
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
        mixin PyException_HEAD;
        PyObject* code;
    }

    struct PyEnvironmentErrorObject {
        mixin PyException_HEAD;
        PyObject* myerrno;
        PyObject* strerror;
        PyObject* filename;
    }

    version(Windows) {
        struct PyWindowsErrorObject {
            mixin PyException_HEAD;
            PyObject* myerrno;
            PyObject* strerror;
            PyObject* filename;
            PyObject* winerror;
        }
    }
}

void PyErr_SetNone(PyObject*);
void PyErr_SetObject(PyObject*, PyObject*);
void PyErr_SetString(PyObject* exception, const(char)* string);
PyObject* PyErr_Occurred();
void PyErr_Clear();
void PyErr_Fetch(PyObject**, PyObject**, PyObject**);
void PyErr_Restore(PyObject*, PyObject*, PyObject*);
version(Python_3_0_Or_Later) {
    void Py_FatalError(const(char)* message);
}

int PyErr_GivenExceptionMatches(PyObject*, PyObject*);
int PyErr_ExceptionMatches(PyObject*);
void PyErr_NormalizeException(PyObject**, PyObject**, PyObject**);
version(Python_2_5_Or_Later) {
    int PyExceptionClass_Check()(PyObject* x) {
        version(Python_3_0_Or_Later) {
            return (PyType_Check((x)) && 
                    PyType_FastSubclass(cast(PyTypeObject*)x, 
                        Py_TPFLAGS_BASE_EXC_SUBCLASS));
        }else version(Python_2_6_Or_Later) {
            return (PyClass_Check(x) || (PyType_Check(x) &&
                        PyType_FastSubclass(cast(PyTypeObject*)x, 
                            Py_TPFLAGS_BASE_EXC_SUBCLASS)));
        }else{
            return (PyClass_Check(x) || (PyType_Check(x) &&
                        PyType_IsSubtype(cast(PyTypeObject*)x, 
                            cast(PyTypeObject*) PyExc_BaseException)));
        }
    }

    int PyExceptionInstance_Check()(PyObject* x) {
        version(Python_3_0_Or_Later) {
            return PyType_FastSubclass(x.ob_type, Py_TPFLAGS_BASE_EXC_SUBCLASS);
        }else version(Python_2_6_Or_Later) {
            return (PyInstance_Check(x) ||
                    PyType_FastSubclass(x.ob_type, Py_TPFLAGS_BASE_EXC_SUBCLASS));
        }else{
            return (PyInstance_Check(x) ||
                    PyType_IsSubtype(x.ob_type, 
                        cast(PyTypeObject*) PyExc_BaseException));
        }
    }

    int PyExceptionClass_Name()(PyObject* x) {
        version(Python_3_0_Or_Later) {
            return cast(char*)((cast(PyTypeObject*)x).tp_name);
        }else {
            return (PyClass_Check(x)
                    ? PyString_AS_STRING((cast(PyClassObject*)x).cl_name)
                    : cast(char*)(cast(PyTypeObject*)x).tp_name);
        }
    }

    int PyExceptionInstance_Class()(PyObject* x) {
        version(Python_3_0_Or_Later) {
            return cast(PyObject*)(x.ob_type);
        }else{
            return ((PyInstance_Check(x) 
                        ? cast(PyObject*)(cast(PyInstanceObject*)x).in_class
                        : cast(PyObject*)(x.ob_type)));
        }
    }
}


/* Predefined exceptions */

version(Python_2_5_Or_Later) {
    __gshared PyObject* PyExc_BaseException;
}
__gshared PyObject* PyExc_Exception;
__gshared PyObject* PyExc_StopIteration;
version(Python_2_5_Or_Later) {
    __gshared PyObject* PyExc_GeneratorExit;
}
version(Python_3_0_Or_Later) {
}else{
    __gshared PyObject* PyExc_StandardError;
}
__gshared PyObject* PyExc_ArithmeticError;
__gshared PyObject* PyExc_LookupError;

__gshared PyObject* PyExc_AssertionError;
__gshared PyObject* PyExc_AttributeError;
__gshared PyObject* PyExc_EOFError;
__gshared PyObject* PyExc_FloatingPointError;
__gshared PyObject* PyExc_EnvironmentError;
__gshared PyObject* PyExc_IOError;
__gshared PyObject* PyExc_OSError;
__gshared PyObject* PyExc_ImportError;
__gshared PyObject* PyExc_IndexError;
__gshared PyObject* PyExc_KeyError;
__gshared PyObject* PyExc_KeyboardInterrupt;
__gshared PyObject* PyExc_MemoryError;
__gshared PyObject* PyExc_NameError;
__gshared PyObject* PyExc_OverflowError;
__gshared PyObject* PyExc_RuntimeError;
__gshared PyObject* PyExc_NotImplementedError;
__gshared PyObject* PyExc_SyntaxError;
__gshared PyObject* PyExc_IndentationError;
__gshared PyObject* PyExc_TabError;
__gshared PyObject* PyExc_ReferenceError;
__gshared PyObject* PyExc_SystemError;
__gshared PyObject* PyExc_SystemExit;
__gshared PyObject* PyExc_TypeError;
__gshared PyObject* PyExc_UnboundLocalError;
__gshared PyObject* PyExc_UnicodeError;
__gshared PyObject* PyExc_UnicodeEncodeError;
__gshared PyObject* PyExc_UnicodeDecodeError;
__gshared PyObject* PyExc_UnicodeTranslateError;
__gshared PyObject* PyExc_ValueError;
__gshared PyObject* PyExc_ZeroDivisionError;
version(Windows) {
    __gshared PyObject* PyExc_WindowsError;
}
// ??!
version(VMS) {
__gshared PyObject* PyExc_VMSError;
}
version(Python_2_6_Or_Later) {
    __gshared PyObject* PyExc_BufferError;
}

version(Python_3_0_Or_Later) {
}else{
    __gshared PyObject* PyExc_MemoryErrorInst;
}
version(Python_2_6_Or_Later) {
    __gshared PyObject* PyExc_RecursionErrorInst;
}

/* Predefined warning categories */
__gshared PyObject* PyExc_Warning;
__gshared PyObject* PyExc_UserWarning;
__gshared PyObject* PyExc_DeprecationWarning;
__gshared PyObject* PyExc_PendingDeprecationWarning;
__gshared PyObject* PyExc_SyntaxWarning;
/* PyExc_OverflowWarning will go away for Python 2.5 */
version(Python_2_5_Or_Later) {
}else{
    __gshared PyObject* PyExc_OverflowWarning;
}
__gshared PyObject* PyExc_RuntimeWarning;
__gshared PyObject* PyExc_FutureWarning;
version(Python_2_5_Or_Later) {
    __gshared PyObject* PyExc_ImportWarning;
    __gshared PyObject* PyExc_UnicodeWarning;
}
version(Python_2_6_Or_Later) {
    __gshared PyObject* PyExc_BytesWarning;
}

version(Python_3_0_Or_Later) {
    __gshared PyObject* PyExc_ResourceWarning;

    /* Traceback manipulation (PEP 3134) */
    int PyException_SetTraceback(PyObject*, PyObject*);
    PyObject* PyException_GetTraceback(PyObject*);

    /* Cause manipulation (PEP 3134) */
    PyObject* PyException_GetCause(PyObject*);
    void PyException_SetCause(PyObject*, PyObject*);

    /* Context manipulation (PEP 3134) */
    PyObject* PyException_GetContext(PyObject*);
    void PyException_SetContext(PyObject*, PyObject*);
}

// All predefined Python exception types are dealt with in the global
// variables section toward the end of this file.

int PyErr_BadArgument();
PyObject* PyErr_NoMemory();
PyObject* PyErr_SetFromErrno(PyObject*);
PyObject* PyErr_SetFromErrnoWithFilenameObject(PyObject*, PyObject*);
PyObject* PyErr_SetFromErrnoWithFilename(PyObject* exc, char* filename);
PyObject* PyErr_SetFromErrnoWithUnicodeFilename(PyObject*, Py_UNICODE*);

PyObject* PyErr_Format(PyObject* exception, const(char)* format, ...);

version (Windows) {
    PyObject* PyErr_SetFromWindowsErrWithFilenameObject(int, const(char)*);
    PyObject* PyErr_SetFromWindowsErrWithFilename(int ierr, const(char)* filename);
    PyObject* PyErr_SetFromWindowsErrWithUnicodeFilename(int, Py_UNICODE*);
    PyObject* PyErr_SetFromWindowsErr(int);
    PyObject* PyErr_SetExcFromWindowsErrWithFilenameObject(PyObject*, int, PyObject*);
    PyObject* PyErr_SetExcFromWindowsErrWithFilename(PyObject* exc, int ierr, const(char)* filename);
    PyObject* PyErr_SetExcFromWindowsErrWithUnicodeFilename(PyObject*, int, Py_UNICODE*);
    PyObject* PyErr_SetExcFromWindowsErr(PyObject*, int);
}

// PyErr_BadInternalCall and friends purposely omitted.
void PyErr_BadInternalall();
void _PyErr_BadInternalCall(const(char)* filename, int lineno);

PyObject* PyErr_NewException(const(char)* name, PyObject* base, PyObject* dict);
version(Python_2_7_Or_Later) {
    PyObject* PyErr_NewExceptionWithDoc(
            const(char)* name, const(char)* doc, PyObject* base, PyObject* dict);
}
void PyErr_WriteUnraisable(PyObject*);

version(Python_2_5_Or_Later){
    int PyErr_WarnEx(PyObject*, char*, Py_ssize_t);
}else{
    int PyErr_Warn(PyObject*, char*);
}
int PyErr_WarnExplicit(PyObject*, const(char)*, const(char)*, int, const(char)*, PyObject*);

int PyErr_CheckSignals();
void PyErr_SetInterrupt();

void PyErr_SyntaxLocation(const(char)* filename, int lineno);
version(Python_3_0_Or_Later) {
    void PyErr_SyntaxLocationEx(
            const(char)* filename,       
            int lineno,
            int col_offset);
}
PyObject* PyErr_ProgramText(const(char)* filename, int lineno);

/////////////////////////////////////////////////////////////////////////////
// UNICODE ENCODING ERROR HANDLING INTERFACE
/////////////////////////////////////////////////////////////////////////////
PyObject* PyUnicodeDecodeError_Create(
        const(char)* encoding, 
        const(char)* object, 
        Py_ssize_t length, 
        Py_ssize_t start, 
        Py_ssize_t end, 
        const(char)* reason);

PyObject* PyUnicodeEncodeError_Create(
        const(char)* encoding, 
        Py_UNICODE* object, 
        Py_ssize_t length, 
        Py_ssize_t start, 
        Py_ssize_t end, 
        const(char)* reason);

PyObject* PyUnicodeTranslateError_Create(
        Py_UNICODE* object, 
        Py_ssize_t length, 
        Py_ssize_t start, 
        Py_ssize_t end, 
        const(char)* reason);

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

int PyUnicodeEncodeError_SetReason(PyObject* exc, const(char)* reason);
int PyUnicodeDecodeError_SetReason(PyObject* exc, const(char)* reason);
int PyUnicodeTranslateError_SetReason(PyObject* exc, const(char)* reason);

int PyOS_snprintf(char* str, size_t size, const(char)* format, ...);
int PyOS_vsnprintf(char* str, size_t size, const(char)* format, va_list va);


