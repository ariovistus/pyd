module python2.pythonrun;

import std.c.stdio;
import python2.types;
import python2.object;
import python2.pystate;
import python2.node;

extern(C):
// Python-header-file: Include/pythonrun.h:

struct PyCompilerFlags {
    int cf_flags;
}

void Py_SetProgramName(char*);
char* Py_GetProgramName();

void Py_SetPythonHome(char*);
char* Py_GetPythonHome();

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

int PyRun_AnyFileExFlags(FILE*, const(char)*, int, PyCompilerFlags*);

int PyRun_SimpleStringFlags(const(char)*, PyCompilerFlags*);

int PyRun_SimpleFileExFlags(FILE*,  const(char)*, int, PyCompilerFlags*);

int PyRun_InteractiveOneFlags(FILE*, const(char)*, PyCompilerFlags *);
int PyRun_InteractiveLoopFlags(FILE*, const(char)*, PyCompilerFlags *);

version(Python_2_5_Or_Later){
    _mod* PyParser_ASTFromString(const(char)*, const(char)*, 
            int, PyCompilerFlags*, PyArena*);
    _mod* PyParser_ASTFromFile(FILE*, const(char)*, int, 
            char*, char*, PyCompilerFlags*, int*, PyArena*);
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

PyObject* PyRun_FileExFlags(FILE*, const(char)*, int, PyObject*, PyObject*, int, PyCompilerFlags *);

PyObject* Py_CompileStringFlags(const(char)*, const(char)*, int, PyCompilerFlags *);
// Py_SymtableString is undocumented, so it's omitted here.

void PyErr_Print();
void PyErr_PrintEx(int);
void PyErr_Display(PyObject*, PyObject*, PyObject*);

int Py_AtExit(void function() func);

void Py_Exit(int);

int Py_FdIsInteractive(FILE*, const(char)*);

/* In getpath.c */
char* Py_GetProgramFullPath();
char* Py_GetPrefix();
char* Py_GetExecPrefix();
char* Py_GetPath();

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
void PyString_Fini();
void PyInt_Fini();
void PyFloat_Fini();
void PyOS_FiniInterrupts();
void PyByteArray_Fini();


char* PyOS_Readline(FILE*, FILE*, char*);

__gshared int function() PyOS_InputHook;
__gshared char* function(FILE*, FILE*, char*) PyOS_ReadlineFunctionPointer;
__gshared PyThreadState* _PyOS_ReadlineTState;

