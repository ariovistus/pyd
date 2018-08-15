/**
  Mirror _fileobject.h
  */
module deimos.python.fileobject;

import core.stdc.stdio;
import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/fileobject.h:

version(Python_3_0_Or_Later) {
}else{
    /// subclass of PyObject
    /// Availability: 2.*
    struct PyFileObject {
        mixin PyObject_HEAD;

        /// _
        FILE* f_fp;
        /// _
        PyObject* f_name;
        /// _
        PyObject* f_mode;
        /// _
        int function(FILE*) f_close;
        /** Flag used by 'print' command */
        int f_softspace;
        /** Flag which indicates whether the file is
           open in binary (1) or text (0) mode */
        int f_binary;
        /** Allocated readahead buffer */
        char* f_buf;
        /** Points after last occupied position */
        char* f_bufend;
        /** Current buffer position */
        char* f_bufptr;
        /** Buffer for setbuf(3) and setvbuf(3) */
        char* f_setbuf;
        /** Handle any newline convention */
        int f_univ_newline;
        /** Types of newlines seen */
        int f_newlinetypes;
        /** Skip next \n */
        int f_skipnextlf;
        /// _
        PyObject* f_encoding;
        version(Python_2_6_Or_Later){
            /// Availability: >= 2.6
            PyObject* f_errors;
        }
        /** List of weak references */
        PyObject* weakreflist;
        version(Python_2_6_Or_Later){
            /** Num. currently running sections of code
               using f_fp with the GIL released. */
            /// Availability: >= 2.6
            int unlocked_count;
            /// Availability: >= 2.6
            int readable;
            /// Availability: >= 2.6
            int writable;
        }
    }

    /// Availability: 2.*
    mixin(PyAPI_DATA!"PyTypeObject PyFile_Type");

    // D translation of C macro:
    /// Availability: 2.*
    int PyFile_Check()(PyObject* op) {
        return PyObject_TypeCheck(op, &PyFile_Type);
    }
    // D translation of C macro:
    /// Availability: 2.*
    int PyFile_CheckExact()(PyObject* op) {
        return Py_TYPE(op) == &PyFile_Type;
    }

    /// Availability: 2.*
    PyObject* PyFile_FromString(char*, char*);
    /// Availability: 2.*
    void PyFile_SetBufSize(PyObject*, int);
    /// Availability: 2.*
    int PyFile_SetEncoding(PyObject*, const(char)*);
    version(Python_2_6_Or_Later){
        /// Availability: >= 2.6
        int PyFile_SetEncodingAndErrors(PyObject* , const(char)*, const(char)* errors);
    }
    /// Availability: 2.*
    PyObject* PyFile_FromFile(FILE*, char*, char*, int function(FILE*));
    /// Availability: 2.*
    FILE* PyFile_AsFile(PyObject*);
    version(Python_2_6_Or_Later){
        /// Availability: >= 2.6
        void PyFile_IncUseCount(PyFileObject*);
        /// Availability: >= 2.6
        void PyFile_DecUseCount(PyFileObject*);
    }
    /// Availability: 2.*
    PyObject_BorrowedRef* PyFile_Name(PyObject*);
}
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    PyObject* PyFile_FromFd(int, char *, char *, int, char *, char *,
            char *, int);
}
/// _
PyObject* PyFile_GetLine(PyObject* , int);
/// _
int PyFile_WriteObject(PyObject*, PyObject*, int);
version(Python_3_0_Or_Later) {
}else {
    /// Availability: 2.*
    int PyFile_SoftSpace(PyObject*, int);
}
/// _
int PyFile_WriteString(const(char)*, PyObject*);
/// _
int PyObject_AsFileDescriptor(PyObject*);

/** The default encoding used by the platform file system APIs
   If non-NULL, this is different than the default encoding for strings
*/
mixin(PyAPI_DATA!"const(char)* Py_FileSystemDefaultEncoding");

version(Python_3_6_Or_Later) {
    /// _
    mixin(PyAPI_DATA!"const(char)* Py_FileSystemDefaultEncodeError");
}

version(Python_3_7_Or_Later) {
    /// _
    mixin(PyAPI_DATA!"int Py_UTF8Mode");
}

/// _
enum PY_STDIOTEXTMODE = "b";

/// _
/* Routine to replace fgets() which accept any of \r, \n
   or \r\n as line terminators.
*/
char* Py_UniversalNewlineFgets(char*, int, FILE*, PyObject*);
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    mixin(PyAPI_DATA!"int Py_HasFileSystemDefaultEncoding");
    /// Availability: 3.*
    PyObject* PyFile_NewStdPrinter(int);
    /// Availability: 3.*
    mixin(PyAPI_DATA!"PyTypeObject PyStdPrinter_Type");
}else{
    /** Routines to replace fread() and fgets() which accept any of \r, \n
      or \r\n as line terminators.
     */
    /// Availability: 2.*
    size_t Py_UniversalNewlineFread(char*, size_t, FILE*, PyObject*);
}

version(Python_3_0_Or_Later) {
}else version(Python_2_5_Or_Later) {
    /** A routine to do sanity checking on the file mode string.  returns
      non-zero on if an exception occurred
     */
    /// Availability: 2.*
    int _PyFile_SanitizeMode(char *mode);
}

version(Python_2_7_Or_Later) {
    //#if defined _MSC_VER && _MSC_VER >= 1400
    //int _PyVerify_fd(int fd);
}
