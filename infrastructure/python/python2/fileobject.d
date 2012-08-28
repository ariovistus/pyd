module python2.fileobject;

import std.c.stdio;
import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/fileobject.h:

struct PyFileObject {
    mixin PyObject_HEAD;

    FILE* f_fp;
    PyObject* f_name;
    PyObject* f_mode;
    int function(FILE*) f_close;
    int f_softspace;
    int f_binary;
    char* f_buf;
    char* f_bufend;
    char* f_bufptr;
    char* f_setbuf;
    int f_univ_newline;
    int f_newlinetypes;
    int f_skipnextlf;
    PyObject* f_encoding;
    version(Python_2_6_Or_Later){
        PyObject* f_errors;
    }
    PyObject* weakreflist;
    version(Python_2_6_Or_Later){
        int unlocked_count;         /* Num. currently running sections of code
                                       using f_fp with the GIL released. */
        int readable;
        int writable;
    }
}

__gshared PyTypeObject PyFile_Type;
// D translation of C macro:
int PyFile_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, &PyFile_Type);
}
// D translation of C macro:
int PyFile_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyFile_Type;
}

PyObject* PyFile_FromString(char*, char*);
void PyFile_SetBufSize(PyObject*, int);
int PyFile_SetEncoding(PyObject*, const(char)*);
version(Python_2_6_Or_Later){
    int PyFile_SetEncodingAndErrors(PyObject* , const(char)*, const(char)* errors);
}
PyObject* PyFile_FromFile(FILE*, char*, char*, int function(FILE*));
FILE* PyFile_AsFile(PyObject*);
version(Python_2_6_Or_Later){
    void PyFile_IncUseCount(PyFileObject*);
    void PyFile_DecUseCount(PyFileObject*);
}
PyObject_BorrowedRef* PyFile_Name(PyObject*);
PyObject* PyFile_GetLine(PyObject* , int);
int PyFile_WriteObject(PyObject*, PyObject*, int);
int PyFile_SoftSpace(PyObject*, int);
int PyFile_WriteString(const(char)*, PyObject*);
int PyObject_AsFileDescriptor(PyObject*);

// We deal with char *Py_FileSystemDefaultEncoding in the global variables
// section toward the bottom of this file.

enum PY_STDIOTEXTMODE = "b";

char* Py_UniversalNewlineFgets(char*, int, FILE*, PyObject*);
size_t Py_UniversalNewlineFread(char*, size_t, FILE*, PyObject*);


