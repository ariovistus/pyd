module python2.sysmodule;

import std.c.stdio;
import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/sysmodule.h:

PyObject* PySys_GetObject(char*);
int PySys_SetObject(char*, PyObject*);
FILE* PySys_GetFile(char*, FILE*);
void PySys_SetArgv(int, char**);
version(Python_2_6_Or_Later){
    void PySys_SetArgvEx(int, char**, int);
}
void PySys_SetPath(char*);

void PySys_WriteStdout(const(char)* format, ...);
void PySys_WriteStderr(const(char)* format, ...);

__gshared PyObject* _PySys_TraceFunc;
__gshared PyObject** _PySys_ProfileFunc;

void PySys_ResetWarnOptions();
void PySys_AddWarnOption(char*);
version(Python_2_6_Or_Later){
    int PySys_HasWarnOptions();
}


