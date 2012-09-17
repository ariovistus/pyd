module deimos.python.pythonrun;

import std.c.stdio;
import deimos.python.pyport;
import deimos.python.object;
import deimos.python.pystate;
import deimos.python.node;

extern(C):
// Python-header-file: Include/pythonrun.h:

version(Python_3_2_Or_Later) {
    enum PyCF_MASK = (CO_FUTURE_DIVISION | CO_FUTURE_ABSOLUTE_IMPORT | 
            CO_FUTURE_WITH_STATEMENT | CO_FUTURE_PRINT_FUNCTION | 
            CO_FUTURE_UNICODE_LITERALS | CO_FUTURE_BARRY_AS_BDFL);
}else version(Python_2_6_Or_Later) {
    enum PyCF_MASK = (CO_FUTURE_DIVISION | CO_FUTURE_ABSOLUTE_IMPORT | 
            CO_FUTURE_WITH_STATEMENT | CO_FUTURE_PRINT_FUNCTION | 
            CO_FUTURE_UNICODE_LITERALS);
}else version(Python_2_5_Or_Later) {
    enum PyCF_MASK = (CO_FUTURE_DIVISION | CO_FUTURE_ABSOLUTE_IMPORT | 
            CO_FUTURE_WITH_STATEMENT );
}else {
    enum PyCF_MASK = CO_FUTURE_DIVISION;
}

enum PyCF_SOURCE_IS_UTF8 =  0x0100;
enum PyCF_DONT_IMPLY_DEDENT = 0x0200;

version(Python_2_5_Or_Later) {
    enum PyCF_ONLY_AST = 0x0400;
}
version(Python_3_2_Or_Later) {
    enum PyCF_IGNORE_COOKIE = 0x0800;
}

struct PyCompilerFlags {
    int cf_flags;
}

version(Python_3_2_Or_Later) {
    void Py_SetProgramName(wchar*);
    wchar* Py_GetProgramName();

    void Py_SetPythonHome(wchar*);
    wchar* Py_GetPythonHome();
}else{
    void Py_SetProgramName(char*);
    char* Py_GetProgramName();

    void Py_SetPythonHome(char*);
    char* Py_GetPythonHome();
}

void Py_Initialize();
void Py_InitializeEx(int);
void Py_Finalize();
int Py_IsInitialized();
PyThreadState* Py_NewInterpreter();
void Py_EndInterpreter(PyThreadState*);

version(Python_2_5_Or_Later){
    int PyRun_AnyFile()(FILE* fp, const(char)* name) {
        return PyRun_AnyFileExFlags(fp, name, 0, null);
    }
    int PyRun_AnyFileEx()(FILE* fp, const(char)* name, int closeit) {
        return PyRun_AnyFileExFlags(fp, name, closeit, null);
    }
    int PyRun_AnyFileFlags()(FILE* fp, const(char)* name, PyCompilerFlags* flags) {
        return PyRun_AnyFileExFlags(fp, name, 0, flags);
    }
    int PyRun_SimpleString()(const(char)* s) {
        return PyRun_SimpleStringFlags(s, null);
    }
    int PyRun_SimpleFile()(FILE* f, const(char)* p) {
        return PyRun_SimpleFileExFlags(f, p, 0, null);
    }
    int PyRun_SimpleFileEx()(FILE* f, const(char)* p, int c) {
        return PyRun_SimpleFileExFlags(f, p, c, null);
    }
    int PyRun_InteractiveOne()(FILE* f, const(char)* p) {
        return PyRun_InteractiveOneFlags(f, p, null);
    }
    int PyRun_InteractiveLoop()(FILE* f, const(char)* p) {
        return PyRun_InteractiveLoopFlags(f, p, null);
    }
}else{
    int PyRun_AnyFile(FILE*, const(char)*);
    int PyRun_AnyFileEx(FILE*, const(char)*,int);

    int PyRun_AnyFileFlags(FILE*, const(char)*, PyCompilerFlags *);
    int PyRun_SimpleString(const(char)*);
    int PyRun_SimpleFile(FILE*, const(char)*);
    int PyRun_SimpleFileEx(FILE*, const(char)*, int);
    int PyRun_InteractiveOne(FILE*, const(char)*);
    int PyRun_InteractiveLoop(FILE*, const(char)*);
}

int PyRun_AnyFileExFlags(
        FILE* fp, 
        const(char)* filename, 
        int closeit, 
        PyCompilerFlags* flags);

int PyRun_SimpleStringFlags(const(char)*, PyCompilerFlags*);

int PyRun_SimpleFileExFlags(
        FILE* fp,  
        const(char)* filename, 
        int closeit, 
        PyCompilerFlags* flags);

int PyRun_InteractiveOneFlags(
        FILE* fp, 
        const(char)* filename, 
        PyCompilerFlags* flags);
int PyRun_InteractiveLoopFlags(
        FILE* fp, 
        const(char)* filename, 
        PyCompilerFlags* flags);

version(Python_2_5_Or_Later){
    _mod* PyParser_ASTFromString(
            const(char)* s, 
            const(char)* filename, 
            int start, 
            PyCompilerFlags* flags, 
            PyArena* arena);
    version(Python_3_2_Or_Later) {
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
    node* PyParser_SimpleParseString()(const(char)* s, int b) {
        return PyParser_SimpleParseStringFlags(s, b, 0);
    }
    node* PyParser_SimpleParseFile()(FILE* f, const(char)* s, int b) {
        return PyParser_SimpleParseFileFlags(f, s, b, 0);
    }
}else{
    node* PyParser_SimpleParseString(const(char)*, int);
    node* PyParser_SimpleParseFile(FILE*, const(char)*, int);
    node* PyParser_SimpleParseStringFlagsFilename(const(char)*, const(char)*, int, int);
}

node* PyParser_SimpleParseStringFlags(const(char)*, int, int);
node* PyParser_SimpleParseFileFlags(FILE*, const(char)*,int, int);

PyObject* PyRun_StringFlags( const(char)*, int, PyObject*, PyObject*, PyCompilerFlags*);
version(Python_2_5_Or_Later){
    PyObject* PyRun_String()(const(char)* str, int s, PyObject* g, PyObject* l) {
        return PyRun_StringFlags(str, s, g, l, null);
    }
    PyObject* PyRun_File()(FILE* fp, const(char)* p, int s, PyObject* g, PyObject* l) {
        return PyRun_FileExFlags(fp, p, s, g, l, 0, null);
    }
    PyObject* PyRun_FileEx()(FILE* fp, const(char)* p, int s, PyObject* g, PyObject* l, int c) {
        return PyRun_FileExFlags(fp, p, s, g, l, c, null);
    }
    PyObject* PyRun_FileFlags()(FILE* fp, const(char)* p, int s, PyObject* g, 
            PyObject* l, PyCompilerFlags *flags) {
        return PyRun_FileExFlags(fp, p, s, g, l, 0, flags);
    }
    PyObject* Py_CompileString()(const(char)* str, const(char)* p, int s) {
        return Py_CompileStringFlags(str, p, s, null);
    }
}else{
    PyObject* PyRun_String(const(char)*, int, PyObject*, PyObject*);
    PyObject* PyRun_File(FILE*, const(char)*, int, PyObject*, PyObject*);
    PyObject* PyRun_FileEx(FILE*, const(char)*, int, PyObject*, PyObject*, int);
    PyObject* PyRun_FileFlags(FILE*, const(char)*, int, PyObject*, PyObject*, 
            PyCompilerFlags *);
    PyObject* Py_CompileString(const(char)*, const(char)*, int);
}

PyObject* PyRun_FileExFlags(
        FILE* fp, 
        const(char)* filename, 
        int start, 
        PyObject* globals, 
        PyObject* locals, 
        int closeit, 
        PyCompilerFlags* flags);

version(Python_3_2_Or_Later) {
    auto Py_CompileStringFlags()(const(char)* str, const(char)* p, 
            int s, PyCompilerFlags* f) {
        return Py_CompileStringExFlags(str, p, s, f, -1);
    }
    PyObject* Py_CompileStringExFlags(
            const(char)* str,
            const(char)* filename,
            int start,
            PyCompilerFlags* flags,
            int optimize);
}else{
    PyObject* Py_CompileStringFlags(
            const(char)* str, 
            const(char)* filename, 
            int, 
            PyCompilerFlags* flags);
}

symtable* Py_SymtableString(
    const(char)* str,
    const(char)* filename,
    int start);

void PyErr_Print();
void PyErr_PrintEx(int);
void PyErr_Display(PyObject*, PyObject*, PyObject*);
version(Python_3_2_Or_Later) {
    void _Py_PyAtExit(void function() func);
}

int Py_AtExit(void function() func);

void Py_Exit(int);

version(Python_3_2_Or_Later) {
    void _Py_RestoreSignals();
}

int Py_FdIsInteractive(FILE*, const(char)*);

version(Python_3_2_Or_Later) {
    int Py_Main(int argc, wchar** argv);
}else{
    int Py_Main(int argc, char** argv);
}

/* In getpath.c */
version(Python_3_2_Or_Later) {
    wchar* Py_GetProgramFullPath();
    wchar* Py_GetPrefix();
    wchar* Py_GetExecPrefix();
    wchar* Py_GetPath();
    void Py_SetPath(const(wchar)*);
    version(Windows) {
        int _Py_CheckPython3();
    }
}else{
    char* Py_GetProgramFullPath();
    char* Py_GetPrefix();
    char* Py_GetExecPrefix();
    char* Py_GetPath();
}

/* In their own files */
const(char)* Py_GetVersion();
const(char)* Py_GetPlatform();
const(char)* Py_GetCopyright();
const(char)* Py_GetCompiler();
const(char)* Py_GetBuildInfo();

/* Various internal finalizers */
void _PyExc_Fini();
void _PyImport_Fini();
void PyMethod_Fini();
void PyFrame_Fini();
void PyCFunction_Fini();
void PyDict_Fini();
void PyTuple_Fini();
void PyList_Fini();
void PySet_Fini();
version(Python_3_2_Or_Later) {
    void PyBytes_Fini();
    void PyByteArray_Fini();
}else{
    void PyString_Fini();
    void PyInt_Fini();
}
void PyFloat_Fini();
void PyOS_FiniInterrupts();
void PyByteArray_Fini();


char* PyOS_Readline(FILE*, FILE*, char*);

__gshared int function() PyOS_InputHook;
__gshared char* function(FILE*, FILE*, char*) PyOS_ReadlineFunctionPointer;
__gshared PyThreadState* _PyOS_ReadlineTState;

