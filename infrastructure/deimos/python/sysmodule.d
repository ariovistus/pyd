module deimos.python.sysmodule;

import std.c.stdio;
import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/sysmodule.h:

PyObject* PySys_GetObject(const(char)*);
int PySys_SetObject(const(char)*, PyObject*);
version(Python_3_2_Or_Later) {
    void PySys_SetArgv(int, wchar**);
    void PySys_SetArgvEx(int, wchar**, int);
    void PySys_SetPath(wchar*);
}else{
    FILE* PySys_GetFile(char*, FILE*);
    void PySys_SetArgv(int, char**);
    version(Python_2_6_Or_Later){
        void PySys_SetArgvEx(int, char**, int);
    }
    void PySys_SetPath(char*);
}

void PySys_WriteStdout(const(char)* format, ...);
void PySys_WriteStderr(const(char)* format, ...);
version(Python_3_2_Or_Later) {
    void PySys_FormatStdout(const(char)* format, ...);
    void PySys_FormatStderr(const(char)* format, ...);
}

__gshared PyObject* _PySys_TraceFunc;
__gshared PyObject** _PySys_ProfileFunc;

void PySys_ResetWarnOptions();
version(Python_3_2_Or_Later) {
    void PySys_AddWarnOption(const(wchar)*);
    void PySys_AddWarnOptionUnicode(PyObject*);
}else{
    void PySys_AddWarnOption(char*);
}
version(Python_2_6_Or_Later){
    int PySys_HasWarnOptions();
}
version(Python_3_2_Or_Later) {
    void PySys_AddXOption(const(wchar)*);
    PyObject* PySys_GetXOptions();
}


