/**
  Mirror _pyerrors.h
  */
module deimos.python.pyerrors;

import std.c.stdarg;
import deimos.python.pyport;
import deimos.python.object;
import deimos.python.unicodeobject;

extern(C):
// Python-header-file: Include/pyerrors.h:

version(Python_3_0_Or_Later) {
    /// _
    mixin template PyException_HEAD() {
        mixin PyObject_HEAD; 
        /// _
        PyObject* dict;
        /// _
        PyObject* args; 
        /// _
        PyObject* traceback;
        /// _
        PyObject* context; 
        /// _
        PyObject* cause;
    }
}else version(Python_2_5_Or_Later) {
    /// _
    mixin template PyException_HEAD() {
        mixin PyObject_HEAD;
        /// _
        PyObject* dict;
        /// _
        PyObject* args;
        /// _
        PyObject* message;
    }
}

version(Python_2_5_Or_Later) {
    /* Error objects */

    /// Availability: >= 2.5
    struct PyBaseExceptionObject {
        mixin PyException_HEAD;
    }

    /// subclass of PyBaseExceptionObject
    /// Availability: >= 2.5
    struct PySyntaxErrorObject {
        mixin PyException_HEAD;
        /// _
        PyObject* msg;
        /// _
        PyObject* filename;
        /// _
        PyObject* lineno;
        /// _
        PyObject* offset;
        /// _
        PyObject* text;
        /// _
        PyObject* print_file_and_line;
    }

    /// subclass of PyBaseExceptionObject
    /// Availability: >= 2.5
    struct PyUnicodeErrorObject {
        mixin PyException_HEAD;
        /// _
        PyObject* encoding;
        /// _
        PyObject* object;
        version(Python_2_6_Or_Later){
            /// Availability: >= 2.6
            Py_ssize_t start;
            /// Availability: >= 2.6
            Py_ssize_t end;
        }else{
            /// Availability: <= 2.5
            PyObject* start;
            /// Availability: <= 2.5
            PyObject* end;
        }
        /// _
        PyObject* reason;
    }

    /// subclass of PyBaseExceptionObject
    /// Availability: >= 2.5
    struct PySystemExitObject {
        mixin PyException_HEAD;
        /// _
        PyObject* code;
    }

    /// subclass of PyBaseExceptionObject
    /// Availability: >= 2.5
    struct PyEnvironmentErrorObject {
        mixin PyException_HEAD;
        /// _
        PyObject* myerrno;
        /// _
        PyObject* strerror;
        /// _
        PyObject* filename;
    }

    version(Windows) {
        /// subclass of PyBaseExceptionObject
        /// Availability: >= 2.5, Windows only
        struct PyWindowsErrorObject {
            mixin PyException_HEAD;
            /// _
            PyObject* myerrno;
            /// _
            PyObject* strerror;
            /// _
            PyObject* filename;
            /// _
            PyObject* winerror;
        }
    }
}

/// _
void PyErr_SetNone(PyObject*);
/// _
void PyErr_SetObject(PyObject*, PyObject*);
/// _
void PyErr_SetString(PyObject* exception, const(char)* string);
/// _
PyObject* PyErr_Occurred();
/// _
void PyErr_Clear();
/// _
void PyErr_Fetch(PyObject**, PyObject**, PyObject**);
/// _
void PyErr_Restore(PyObject*, PyObject*, PyObject*);
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    void Py_FatalError(const(char)* message);
}

/// _
int PyErr_GivenExceptionMatches(PyObject*, PyObject*);
/// _
int PyErr_ExceptionMatches(PyObject*);
/// _
void PyErr_NormalizeException(PyObject**, PyObject**, PyObject**);
version(Python_2_5_Or_Later) {
    /// Availability: >= 2.5
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

    /// Availability: >= 2.5
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

    /// Availability: >= 2.5
    int PyExceptionClass_Name()(PyObject* x) {
        version(Python_3_0_Or_Later) {
            return cast(char*)((cast(PyTypeObject*)x).tp_name);
        }else {
            return (PyClass_Check(x)
                    ? PyString_AS_STRING((cast(PyClassObject*)x).cl_name)
                    : cast(char*)(cast(PyTypeObject*)x).tp_name);
        }
    }

    /// Availability: >= 2.5
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
    /// Availability: >= 2.5
    __gshared PyObject* PyExc_BaseException;
}
/// _
__gshared PyObject* PyExc_Exception;
/// _
__gshared PyObject* PyExc_StopIteration;
version(Python_2_5_Or_Later) {
    /// Availability: >= 2.5
    __gshared PyObject* PyExc_GeneratorExit;
}
version(Python_3_0_Or_Later) {
}else{
    /// Availability: 2.*
    __gshared PyObject* PyExc_StandardError;
}
/// _
__gshared PyObject* PyExc_ArithmeticError;
/// _
__gshared PyObject* PyExc_LookupError;

/// _
__gshared PyObject* PyExc_AssertionError;
/// _
__gshared PyObject* PyExc_AttributeError;
/// _
__gshared PyObject* PyExc_EOFError;
/// _
__gshared PyObject* PyExc_FloatingPointError;
/// _
__gshared PyObject* PyExc_EnvironmentError;
/// _
__gshared PyObject* PyExc_IOError;
/// _
__gshared PyObject* PyExc_OSError;
/// _
__gshared PyObject* PyExc_ImportError;
/// _
__gshared PyObject* PyExc_IndexError;
/// _
__gshared PyObject* PyExc_KeyError;
/// _
__gshared PyObject* PyExc_KeyboardInterrupt;
/// _
__gshared PyObject* PyExc_MemoryError;
/// _
__gshared PyObject* PyExc_NameError;
/// _
__gshared PyObject* PyExc_OverflowError;
/// _
__gshared PyObject* PyExc_RuntimeError;
/// _
__gshared PyObject* PyExc_NotImplementedError;
/// _
__gshared PyObject* PyExc_SyntaxError;
/// _
__gshared PyObject* PyExc_IndentationError;
/// _
__gshared PyObject* PyExc_TabError;
/// _
__gshared PyObject* PyExc_ReferenceError;
/// _
__gshared PyObject* PyExc_SystemError;
/// _
__gshared PyObject* PyExc_SystemExit;
/// _
__gshared PyObject* PyExc_TypeError;
/// _
__gshared PyObject* PyExc_UnboundLocalError;
/// _
__gshared PyObject* PyExc_UnicodeError;
/// _
__gshared PyObject* PyExc_UnicodeEncodeError;
/// _
__gshared PyObject* PyExc_UnicodeDecodeError;
/// _
__gshared PyObject* PyExc_UnicodeTranslateError;
/// _
__gshared PyObject* PyExc_ValueError;
/// _
__gshared PyObject* PyExc_ZeroDivisionError;
version(Windows) {
    /// Availability: Windows only
    __gshared PyObject* PyExc_WindowsError;
}
// ??!
version(VMS) {
    /// Availability: VMS only
    __gshared PyObject* PyExc_VMSError;
}
version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    __gshared PyObject* PyExc_BufferError;
}

version(Python_3_0_Or_Later) {
}else{
    /// Availability: 2.*
    __gshared PyObject* PyExc_MemoryErrorInst;
}
version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    __gshared PyObject* PyExc_RecursionErrorInst;
}

/** Predefined warning categories */
__gshared PyObject* PyExc_Warning;
/// ditto
__gshared PyObject* PyExc_UserWarning;
/// ditto
__gshared PyObject* PyExc_DeprecationWarning;
/// ditto
__gshared PyObject* PyExc_PendingDeprecationWarning;
/// ditto
__gshared PyObject* PyExc_SyntaxWarning;
/* PyExc_OverflowWarning will go away for Python 2.5 */
version(Python_2_5_Or_Later) {
}else{
    /// Availability: 2.4
    __gshared PyObject* PyExc_OverflowWarning;
}
/// _
__gshared PyObject* PyExc_RuntimeWarning;
/// _
__gshared PyObject* PyExc_FutureWarning;
version(Python_2_5_Or_Later) {
    /// Availability: >= 2.5
    __gshared PyObject* PyExc_ImportWarning;
    /// Availability: >= 2.5
    __gshared PyObject* PyExc_UnicodeWarning;
}
version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    __gshared PyObject* PyExc_BytesWarning;
}

version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    __gshared PyObject* PyExc_ResourceWarning;

    /** Traceback manipulation (PEP 3134) */
    int PyException_SetTraceback(PyObject*, PyObject*);
    /// ditto
    PyObject* PyException_GetTraceback(PyObject*);

    /** Cause manipulation (PEP 3134) */
    PyObject* PyException_GetCause(PyObject*);
    /// ditto
    void PyException_SetCause(PyObject*, PyObject*);

    /** Context manipulation (PEP 3134) */
    PyObject* PyException_GetContext(PyObject*);
    /// ditto
    void PyException_SetContext(PyObject*, PyObject*);
}

/// _
int PyErr_BadArgument();
/// _
PyObject* PyErr_NoMemory();
/// _
PyObject* PyErr_SetFromErrno(PyObject*);
/// _
PyObject* PyErr_SetFromErrnoWithFilenameObject(PyObject*, PyObject*);
/// _
PyObject* PyErr_SetFromErrnoWithFilename(PyObject* exc, char* filename);
/// _
PyObject* PyErr_SetFromErrnoWithUnicodeFilename(PyObject*, Py_UNICODE*);

/// _
PyObject* PyErr_Format(PyObject* exception, const(char)* format, ...);

version (Windows) {
    /// Availability: Windows only
    PyObject* PyErr_SetFromWindowsErrWithFilenameObject(int, const(char)*);
    /// Availability: Windows only
    PyObject* PyErr_SetFromWindowsErrWithFilename(int ierr, const(char)* filename);
    /// Availability: Windows only
    PyObject* PyErr_SetFromWindowsErrWithUnicodeFilename(int, Py_UNICODE*);
    /// Availability: Windows only
    PyObject* PyErr_SetFromWindowsErr(int);
    /// Availability: Windows only
    PyObject* PyErr_SetExcFromWindowsErrWithFilenameObject(PyObject*, int, PyObject*);
    /// Availability: Windows only
    PyObject* PyErr_SetExcFromWindowsErrWithFilename(PyObject* exc, int ierr, const(char)* filename);
    /// Availability: Windows only
    PyObject* PyErr_SetExcFromWindowsErrWithUnicodeFilename(PyObject*, int, Py_UNICODE*);
    /// Availability: Windows only
    PyObject* PyErr_SetExcFromWindowsErr(PyObject*, int);
}

// PyErr_BadInternalCall and friends purposely omitted.
/// _
void PyErr_BadInternalall();
/// _
void _PyErr_BadInternalCall(const(char)* filename, int lineno);

/// _
PyObject* PyErr_NewException(const(char)* name, PyObject* base, PyObject* dict);
version(Python_2_7_Or_Later) {
    /// Availability: >= 2.7
    PyObject* PyErr_NewExceptionWithDoc(
            const(char)* name, const(char)* doc, PyObject* base, PyObject* dict);
}
/// _
void PyErr_WriteUnraisable(PyObject*);

version(Python_2_5_Or_Later){
    /// Availability: >= 2.5
    int PyErr_WarnEx(PyObject*, char*, Py_ssize_t);
}else{
    /// Availability: 2.4
    int PyErr_Warn(PyObject*, char*);
}
/// _
int PyErr_WarnExplicit(PyObject*, const(char)*, const(char)*, int, const(char)*, PyObject*);

/// _
int PyErr_CheckSignals();
/// _
void PyErr_SetInterrupt();

/// _
void PyErr_SyntaxLocation(const(char)* filename, int lineno);
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    void PyErr_SyntaxLocationEx(
            const(char)* filename,       
            int lineno,
            int col_offset);
}
/// _
PyObject* PyErr_ProgramText(const(char)* filename, int lineno);

//-//////////////////////////////////////////////////////////////////////////
// UNICODE ENCODING ERROR HANDLING INTERFACE
//-//////////////////////////////////////////////////////////////////////////
/** create a UnicodeDecodeError object */
PyObject* PyUnicodeDecodeError_Create(
        const(char)* encoding, 
        const(char)* object, 
        Py_ssize_t length, 
        Py_ssize_t start, 
        Py_ssize_t end, 
        const(char)* reason);

/** create a UnicodeEncodeError object */
PyObject* PyUnicodeEncodeError_Create(
        const(char)* encoding, 
        Py_UNICODE* object, 
        Py_ssize_t length, 
        Py_ssize_t start, 
        Py_ssize_t end, 
        const(char)* reason);

/** create a UnicodeTranslateError object */
PyObject* PyUnicodeTranslateError_Create(
        Py_UNICODE* object, 
        Py_ssize_t length, 
        Py_ssize_t start, 
        Py_ssize_t end, 
        const(char)* reason);

/** get the encoding attribute */
PyObject* PyUnicodeEncodeError_GetEncoding(PyObject*);
/// ditto
PyObject* PyUnicodeDecodeError_GetEncoding(PyObject*);

/** get the object attribute */
PyObject* PyUnicodeEncodeError_GetObject(PyObject*);
/// ditto
PyObject* PyUnicodeDecodeError_GetObject(PyObject*);
/// ditto
PyObject* PyUnicodeTranslateError_GetObject(PyObject*);

/** get the value of the start attribute (the int * may not be NULL)
   return 0 on success, -1 on failure */
int PyUnicodeEncodeError_GetStart(PyObject*, Py_ssize_t*);
/// ditto
int PyUnicodeDecodeError_GetStart(PyObject*, Py_ssize_t*);
/// ditto
int PyUnicodeTranslateError_GetStart(PyObject*, Py_ssize_t*);

/** assign a new value to the start attribute
   return 0 on success, -1 on failure */
int PyUnicodeEncodeError_SetStart(PyObject*, Py_ssize_t);
/// ditto
int PyUnicodeDecodeError_SetStart(PyObject*, Py_ssize_t);
/// ditto
int PyUnicodeTranslateError_SetStart(PyObject* , Py_ssize_t);

/** get the value of the end attribute (the int *may not be NULL)
 return 0 on success, -1 on failure */
int PyUnicodeEncodeError_GetEnd(PyObject*, Py_ssize_t*);
/// ditto
int PyUnicodeDecodeError_GetEnd(PyObject*, Py_ssize_t*);
/// ditto
int PyUnicodeTranslateError_GetEnd(PyObject* , Py_ssize_t*);

/** assign a new value to the end attribute
   return 0 on success, -1 on failure */
int PyUnicodeEncodeError_SetEnd(PyObject*, Py_ssize_t);
/// ditto
int PyUnicodeDecodeError_SetEnd(PyObject*, Py_ssize_t);
/// ditto
int PyUnicodeTranslateError_SetEnd(PyObject*, Py_ssize_t);

/** get the value of the reason attribute */
PyObject* PyUnicodeEncodeError_GetReason(PyObject*);
/// ditto
PyObject* PyUnicodeDecodeError_GetReason(PyObject*);
/// ditto
PyObject* PyUnicodeTranslateError_GetReason(PyObject*);

/** assign a new value to the reason attribute
   return 0 on success, -1 on failure */
int PyUnicodeEncodeError_SetReason(PyObject* exc, const(char)* reason);
/// ditto
int PyUnicodeDecodeError_SetReason(PyObject* exc, const(char)* reason);
/// ditto
int PyUnicodeTranslateError_SetReason(PyObject* exc, const(char)* reason);

/// _
int PyOS_snprintf(char* str, size_t size, const(char)* format, ...);
/// _
int PyOS_vsnprintf(char* str, size_t size, const(char)* format, va_list va);


