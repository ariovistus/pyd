/**
  Mirror _pythonrun.h

  Interfaces to parse and execute pieces of python code

See_Also:
<a href="http://docs.python.org/c-api/veryhigh.html"> The Very High Level Layer </a>
  */
module deimos.python.pythonrun;

import core.stdc.stdio;
import core.stdc.stddef : wchar_t;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.code;
import deimos.python.compile;
import deimos.python.pyarena;
import deimos.python.pystate;
import deimos.python.node;
import deimos.python.symtable;

extern(C):
// Python-header-file: Include/pythonrun.h:

version(Python_3_7_Or_Later){
    // moved to compile.d
}else version(Python_3_2_Or_Later) {
    /// _
    enum PyCF_MASK = (CO_FUTURE_DIVISION | CO_FUTURE_ABSOLUTE_IMPORT |
            CO_FUTURE_WITH_STATEMENT | CO_FUTURE_PRINT_FUNCTION |
            CO_FUTURE_UNICODE_LITERALS | CO_FUTURE_BARRY_AS_BDFL);
}else version(Python_2_6_Or_Later) {
    /// _
    enum PyCF_MASK = (CO_FUTURE_DIVISION | CO_FUTURE_ABSOLUTE_IMPORT |
            CO_FUTURE_WITH_STATEMENT | CO_FUTURE_PRINT_FUNCTION |
            CO_FUTURE_UNICODE_LITERALS);
}else version(Python_2_5_Or_Later) {
    /// _
    enum PyCF_MASK = (CO_FUTURE_DIVISION | CO_FUTURE_ABSOLUTE_IMPORT |
            CO_FUTURE_WITH_STATEMENT );
}else {
    /// _
    enum PyCF_MASK = CO_FUTURE_DIVISION;
}

version(Python_3_7_Or_Later) {
    // moved to compile.d
    import deimos.python.compile;
}else{
    /// _
    enum PyCF_SOURCE_IS_UTF8 =  0x0100;
    /// _
    enum PyCF_DONT_IMPLY_DEDENT = 0x0200;

    version(Python_2_5_Or_Later) {
        /// Availability: >= 2.5
        enum PyCF_ONLY_AST = 0x0400;
    }
    version(Python_3_2_Or_Later) {
        /// Availability: >= 3.2
        enum PyCF_IGNORE_COOKIE = 0x0800;
    }

    /// _
    struct PyCompilerFlags {
        /// _
        int cf_flags;
    }
}


version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    void Py_SetProgramName(wchar_t*);
    /// Availability: >= 3.2
    wchar_t* Py_GetProgramName();

    /// Availability: >= 3.2
    void Py_SetPythonHome(wchar_t*);
    /// Availability: >= 3.2
    wchar_t* Py_GetPythonHome();
}else{
    /// Availability: <= 2.7
    void Py_SetProgramName(char*);
    /// Availability: <= 2.7
    char* Py_GetProgramName();

    /// Availability: <= 2.7
    void Py_SetPythonHome(char*);
    /// Availability: <= 2.7
    char* Py_GetPythonHome();
}

/**
  Initialize the Python interpreter. For embedding python, this should
  be called before accessing other Python/C API functions, with the
  following exceptions:

  For Python 3, PyImport_AppendInittab and PyImport_ExtendInittab should
  be called before Py_Initialize.
  */
void Py_Initialize();
/// _
void Py_InitializeEx(int);
/// _
void Py_Finalize();
/// _
int Py_IsInitialized();
/// _
PyThreadState* Py_NewInterpreter();
/// _
void Py_EndInterpreter(PyThreadState*);

version(Python_2_5_Or_Later){
    /// _
    int PyRun_AnyFile()(FILE* fp, const(char)* name) {
        return PyRun_AnyFileExFlags(fp, name, 0, null);
    }
    /// _
    int PyRun_AnyFileEx()(FILE* fp, const(char)* name, int closeit) {
        return PyRun_AnyFileExFlags(fp, name, closeit, null);
    }
    /// _
    int PyRun_AnyFileFlags()(FILE* fp, const(char)* name, PyCompilerFlags* flags) {
        return PyRun_AnyFileExFlags(fp, name, 0, flags);
    }
    /// _
    int PyRun_SimpleString()(const(char)* s) {
        return PyRun_SimpleStringFlags(s, null);
    }
    /// _
    int PyRun_SimpleFile()(FILE* f, const(char)* p) {
        return PyRun_SimpleFileExFlags(f, p, 0, null);
    }
    /// _
    int PyRun_SimpleFileEx()(FILE* f, const(char)* p, int c) {
        return PyRun_SimpleFileExFlags(f, p, c, null);
    }
    /// _
    int PyRun_InteractiveOne()(FILE* f, const(char)* p) {
        return PyRun_InteractiveOneFlags(f, p, null);
    }
    /// _
    int PyRun_InteractiveLoop()(FILE* f, const(char)* p) {
        return PyRun_InteractiveLoopFlags(f, p, null);
    }
}else{
    /// _
    int PyRun_AnyFile(FILE*, const(char)*);
    /// _
    int PyRun_AnyFileEx(FILE*, const(char)*,int);

    /// _
    int PyRun_AnyFileFlags(FILE*, const(char)*, PyCompilerFlags *);
    /// _
    int PyRun_SimpleString(const(char)*);
    /// _
    int PyRun_SimpleFile(FILE*, const(char)*);
    /// _
    int PyRun_SimpleFileEx(FILE*, const(char)*, int);
    /// _
    int PyRun_InteractiveOne(FILE*, const(char)*);
    /// _
    int PyRun_InteractiveLoop(FILE*, const(char)*);
}

/// _
int PyRun_AnyFileExFlags(
        FILE* fp,
        const(char)* filename,
        int closeit,
        PyCompilerFlags* flags);

/// _
int PyRun_SimpleStringFlags(const(char)*, PyCompilerFlags*);

/// _
int PyRun_SimpleFileExFlags(
        FILE* fp,
        const(char)* filename,
        int closeit,
        PyCompilerFlags* flags);

/// _
int PyRun_InteractiveOneFlags(
        FILE* fp,
        const(char)* filename,
        PyCompilerFlags* flags);
/// _
int PyRun_InteractiveLoopFlags(
        FILE* fp,
        const(char)* filename,
        PyCompilerFlags* flags);

version(Python_2_5_Or_Later) {
    /// Availability: >= 2.5
    _mod* PyParser_ASTFromString(
            const(char)* s,
            const(char)* filename,
            int start,
            PyCompilerFlags* flags,
            PyArena* arena);
    version(Python_3_2_Or_Later) {
        /// Availability: >= 3.2
        _mod* PyParser_ASTFromFile(
                FILE* fp,
                const(char)* filename,
                const(char)* enc,
                int start,
                char* ps1,
                char* ps2,
                PyCompilerFlags* flags,
                int* errcode,
                PyArena* arena);
    }else{
        /// Availability: <= 2.7
        _mod* PyParser_ASTFromFile(
                FILE* fp,
                const(char)* filename,
                int start,
                char* ps1,
                char* ps2,
                PyCompilerFlags* flags,
                int* errcode,
                PyArena* arena);
    }
    /// _
    node* PyParser_SimpleParseString()(const(char)* s, int b) {
        return PyParser_SimpleParseStringFlags(s, b, 0);
    }
    /// _
    node* PyParser_SimpleParseFile()(FILE* f, const(char)* s, int b) {
        return PyParser_SimpleParseFileFlags(f, s, b, 0);
    }
}else{
    /// _
    node* PyParser_SimpleParseString(const(char)*, int);
    /// _
    node* PyParser_SimpleParseFile(FILE*, const(char)*, int);
    /// Availability: 2.4
    node* PyParser_SimpleParseStringFlagsFilename(const(char)*, const(char)*, int, int);
}

/// _
node* PyParser_SimpleParseStringFlags(const(char)*, int, int);
/// _
node* PyParser_SimpleParseFileFlags(FILE*, const(char)*,int, int);

    /**
Params:
str = python code to run
s = start symbol. one of Py_eval_input, Py_file_input, Py_single_input.
g = globals variables. should be a dict.
l = local variables. should be a dict.
flags = compilation flags (modified by `from __future__ import xx`).

Returns:
result of executing code, or null if an exception was raised.
*/
PyObject* PyRun_StringFlags(
        const(char)* str,
        int s,
        PyObject* g,
        PyObject* g,
        PyCompilerFlags* flags);

version(Python_2_5_Or_Later){
    /**
Params:
str = python code to run
s = start symbol. one of Py_eval_input, Py_file_input, Py_single_input.
g = globals variables. should be a dict.
l = local variables. should be a dict.

Returns:
result of executing code, or null if an exception was raised.
     */
    PyObject* PyRun_String()(
            const(char)* str,
            int s,
            PyObject* g,
            PyObject* l) {
        return PyRun_StringFlags(str, s, g, l, null);
    }
    /// _
    PyObject* PyRun_File()(FILE* fp, const(char)* p, int s, PyObject* g, PyObject* l) {
        return PyRun_FileExFlags(fp, p, s, g, l, 0, null);
    }
    /// _
    PyObject* PyRun_FileEx()(FILE* fp, const(char)* p, int s, PyObject* g, PyObject* l, int c) {
        return PyRun_FileExFlags(fp, p, s, g, l, c, null);
    }
    /// _
    PyObject* PyRun_FileFlags()(FILE* fp, const(char)* p, int s, PyObject* g,
            PyObject* l, PyCompilerFlags *flags) {
        return PyRun_FileExFlags(fp, p, s, g, l, 0, flags);
    }
    /// _
    PyObject* Py_CompileString()(const(char)* str, const(char)* p, int s) {
        return Py_CompileStringFlags(str, p, s, null);
    }
}else{
    /**
Params:
str = python code to run
s = start symbol. one of Py_eval_input, Py_file_input, Py_single_input.
g = globals variables. should be a dict.
l = local variables. should be a dict.

Returns:
result of executing code, or null if an exception was raised.
*/
    PyObject* PyRun_String(const(char)* str, int s, PyObject* g, PyObject* l);
    /// _
    PyObject* PyRun_File(FILE*, const(char)*, int, PyObject*, PyObject*);
    /// _
    PyObject* PyRun_FileEx(FILE*, const(char)*, int, PyObject*, PyObject*, int);
    /// _
    PyObject* PyRun_FileFlags(FILE*, const(char)*, int, PyObject*, PyObject*,
            PyCompilerFlags *);
    /// _
    PyObject* Py_CompileString(const(char)*, const(char)*, int);
}

/// _
PyObject* PyRun_FileExFlags(
        FILE* fp,
        const(char)* filename,
        int start,
        PyObject* globals,
        PyObject* locals,
        int closeit,
        PyCompilerFlags* flags);

version(Python_3_2_Or_Later) {
    /// _
    auto Py_CompileStringFlags()(const(char)* str, const(char)* p,
            int s, PyCompilerFlags* f) {
        return Py_CompileStringExFlags(str, p, s, f, -1);
    }
    /// Availability: >= 3.2
    PyObject* Py_CompileStringExFlags(
            const(char)* str,
            const(char)* filename,
            int start,
            PyCompilerFlags* flags,
            int optimize);
}else{
    /// _
    PyObject* Py_CompileStringFlags(
            const(char)* str,
            const(char)* filename,
            int,
            PyCompilerFlags* flags);
}

/// _
symtable* Py_SymtableString(
    const(char)* str,
    const(char)* filename,
    int start);

/// _
void PyErr_Print();
/// _
void PyErr_PrintEx(int);
/// _
void PyErr_Display(PyObject*, PyObject*, PyObject*);
version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    void _Py_PyAtExit(void function() func);
}

/// _
int Py_AtExit(void function() func);

/// _
void Py_Exit(int);

version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    void _Py_RestoreSignals();
}

/// _
int Py_FdIsInteractive(FILE*, const(char)*);

version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    int Py_Main(int argc, wchar_t** argv);
}else{
    /// Availability: <= 2.7
    int Py_Main(int argc, wchar_t** argv);
}

/* In getpath.c */
version(Python_3_0_Or_Later) {
    /// Availability: >= 3.0
    wchar_t* Py_GetProgramFullPath();
    /// Availability: >= 3.0
    wchar_t* Py_GetPrefix();
    /// Availability: >= 3.0
    wchar_t* Py_GetExecPrefix();
    /// Availability: >= 3.0
    wchar_t* Py_GetPath();
    version(Python_3_2_Or_Later) {
        /// Availability: >= 3.2
        void Py_SetPath(const(wchar_t)*);
    }
    version(Windows) {
        /// Availability: >= 3.0, Windows only
        int _Py_CheckPython3();
    }
}else{
    char* Py_GetProgramFullPath();
    char* Py_GetPrefix();
    char* Py_GetExecPrefix();
    char* Py_GetPath();
}

/* In their own files */
/// _
const(char)* Py_GetVersion();
/// _
const(char)* Py_GetPlatform();
/// _
const(char)* Py_GetCopyright();
/// _
const(char)* Py_GetCompiler();
/// _
const(char)* Py_GetBuildInfo();

/* Various internal finalizers */
/// _
void _PyExc_Fini();
/// _
void _PyImport_Fini();
/// _
void PyMethod_Fini();
/// _
void PyFrame_Fini();
/// _
void PyCFunction_Fini();
/// _
void PyDict_Fini();
/// _
void PyTuple_Fini();
/// _
void PyList_Fini();
/// _
void PySet_Fini();
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    void PyBytes_Fini();
    /// Availability: 3.*
    void PyByteArray_Fini();
}else{
    /// Availability: 2.*
    void PyString_Fini();
    /// Availability: 2.*
    void PyInt_Fini();
}
/// _
void PyFloat_Fini();
/// _
void PyOS_FiniInterrupts();
/// _
void PyByteArray_Fini();
version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    void PySlice_Fini();
    /// Availability: >= 3.2
    mixin(PyAPI_DATA!"PyThreadState* _Py_Finalizing");
}


/// _
char* PyOS_Readline(FILE*, FILE*, char*);

/// _
mixin(PyAPI_DATA!"int function() PyOS_InputHook");
/// _
mixin(PyAPI_DATA!"char* function(FILE*, FILE*, char*)
    PyOS_ReadlineFunctionPointer");
/// _
mixin(PyAPI_DATA!"PyThreadState* _PyOS_ReadlineTState");

