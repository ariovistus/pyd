/**
  Mirror _sysmodule.h

  System module interface 
  */
module deimos.python.sysmodule;

import std.c.stdio;
import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/sysmodule.h:

/// _
PyObject* PySys_GetObject(const(char)*);
/// _
int PySys_SetObject(const(char)*, PyObject*);
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    void PySys_SetArgv(int, wchar**);
    /// Availability: 3.*
    void PySys_SetArgvEx(int, wchar**, int);
    /// Availability: 3.*
    void PySys_SetPath(wchar*);
}else{
    /// Availability: 2.*
    FILE* PySys_GetFile(char*, FILE*);
    /// Availability: 2.*
    void PySys_SetArgv(int, char**);
    /// Availability: 2.*
    version(Python_2_6_Or_Later){
        /// Availability: >= 2.6
        void PySys_SetArgvEx(int, char**, int);
    }
    /// Availability: 2.*
    void PySys_SetPath(char*);
}

/// _
void PySys_WriteStdout(const(char)* format, ...);
/// _
void PySys_WriteStderr(const(char)* format, ...);
version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    void PySys_FormatStdout(const(char)* format, ...);
    /// Availability: >= 3.2
    void PySys_FormatStderr(const(char)* format, ...);
}

/// _
mixin(PyAPI_DATA!"PyObject* _PySys_TraceFunc");
/// _
mixin(PyAPI_DATA!"PyObject** _PySys_ProfileFunc");

/// _
void PySys_ResetWarnOptions();
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    void PySys_AddWarnOption(const(wchar)*);
    version(Python_3_2_Or_Later) {
        /// Availability: >= 3.2
        void PySys_AddWarnOptionUnicode(PyObject*);
    }
}else{
    /// Availability: 2.*
    void PySys_AddWarnOption(char*);
}
version(Python_2_6_Or_Later){
    /// Availability: >= 2.6
    int PySys_HasWarnOptions();
}
version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    void PySys_AddXOption(const(wchar)*);
    /// Availability: >= 3.2
    PyObject* PySys_GetXOptions();
}


