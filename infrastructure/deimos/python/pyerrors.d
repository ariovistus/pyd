/**
  Mirror _pyerrors.h
  */
module deimos.python.pyerrors;

import core.stdc.stdarg;
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

        version(Python_3_4_Or_Later) {
            /// Availability >= 3.4
            char suppress_content;
        }
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
        version(Python_3_4_Or_Later) {
            /// Availability: >= 3.4
            PyObject* filename2;
            /// Availability: >= 3.4
            Py_ssize_t written;
        }
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
            version(Python_3_4_Or_Later) {
                /// Availability: >= 3.4
                PyObject* filename2;
            }
            /// _
            PyObject* winerror;
            version(Python_3_4_Or_Later) {
                /// Availability: >= 3.4
                Py_ssize_t written;
            }
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
    mixin(PyAPI_DATA!"PyObject* PyExc_BaseException");
}
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_Exception");
version(Python_3_5_Or_Later) {
    /// _
    mixin(PyAPI_DATA!"PyObject* PyExc_StopAsyncIteration");
}
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_StopIteration");
version(Python_2_5_Or_Later) {
    /// Availability: >= 2.5
    mixin(PyAPI_DATA!"PyObject* PyExc_GeneratorExit");
}
version(Python_3_0_Or_Later) {
}else{
    /// Availability: 2.*
    mixin(PyAPI_DATA!"PyObject* PyExc_StandardError");
}
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_ArithmeticError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_LookupError");

/// _
mixin(PyAPI_DATA!"PyObject* PyExc_AssertionError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_AttributeError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_EOFError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_FloatingPointError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_EnvironmentError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_IOError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_OSError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_ImportError");

version(Python_3_6_Or_Later) {
    /// _
    mixin(PyAPI_DATA!"PyObject* PyExc_ModuleNotFoundError");
}
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_IndexError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_KeyError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_KeyboardInterrupt");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_MemoryError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_NameError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_OverflowError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_RuntimeError");
version(Python_3_5_Or_Later) {
    /// _
    mixin(PyAPI_DATA!"PyObject* PyExc_RecursionError;");
}
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_NotImplementedError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_SyntaxError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_IndentationError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_TabError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_ReferenceError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_SystemError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_SystemExit");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_TypeError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_UnboundLocalError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_UnicodeError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_UnicodeEncodeError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_UnicodeDecodeError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_UnicodeTranslateError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_ValueError");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_ZeroDivisionError");
version(Windows) {
    /// Availability: Windows only
    mixin(PyAPI_DATA!"PyObject* PyExc_WindowsError");
}
// ??!
version(VMS) {
    /// Availability: VMS only
    mixin(PyAPI_DATA!"PyObject* PyExc_VMSError");
}
version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    mixin(PyAPI_DATA!"PyObject* PyExc_BufferError");
}

version(Python_3_0_Or_Later) {
}else{
    /// Availability: 2.*
    mixin(PyAPI_DATA!"PyObject* PyExc_MemoryErrorInst");
}
version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    mixin(PyAPI_DATA!"PyObject* PyExc_RecursionErrorInst");
}

/** Predefined warning categories */
mixin(PyAPI_DATA!"PyObject* PyExc_Warning");
/// ditto
mixin(PyAPI_DATA!"PyObject* PyExc_UserWarning");
/// ditto
mixin(PyAPI_DATA!"PyObject* PyExc_DeprecationWarning");
/// ditto
mixin(PyAPI_DATA!"PyObject* PyExc_PendingDeprecationWarning");
/// ditto
mixin(PyAPI_DATA!"PyObject* PyExc_SyntaxWarning");
/* PyExc_OverflowWarning will go away for Python 2.5 */
version(Python_2_5_Or_Later) {
}else{
    /// Availability: 2.4
    mixin(PyAPI_DATA!"PyObject* PyExc_OverflowWarning");
}
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_RuntimeWarning");
/// _
mixin(PyAPI_DATA!"PyObject* PyExc_FutureWarning");
version(Python_2_5_Or_Later) {
    /// Availability: >= 2.5
    mixin(PyAPI_DATA!"PyObject* PyExc_ImportWarning");
    /// Availability: >= 2.5
    mixin(PyAPI_DATA!"PyObject* PyExc_UnicodeWarning");
}
version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    mixin(PyAPI_DATA!"PyObject* PyExc_BytesWarning");
}

version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    mixin(PyAPI_DATA!"PyObject* PyExc_ResourceWarning");

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

version(Python_3_6_Or_Later) {
    PyObject* PyErr_SetImportErrorSubclass(PyObject*, PyObject*, PyObject*, PyObject*);
}

version(Python_3_5_Or_Later) {
    PyObject* PyErr_SetImportError(PyObject*, PyObject*, PyObject*);
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


