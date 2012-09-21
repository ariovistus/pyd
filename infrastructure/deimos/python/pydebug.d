/**
  Mirror _pydebug.h
  */
module deimos.python.pydebug;

import std.c.stdlib;

extern(C):
// Python-header-file: Include/node.h

/// _
__gshared int Py_DebugFlag;
/// _
__gshared int Py_VerboseFlag;
version(Python_3_0_Or_Later) {
    __gshared int Py_QuietFlag;
}
/// _
__gshared int Py_InteractiveFlag;
/// _
__gshared int Py_OptimizeFlag;
/// _
__gshared int Py_NoSiteFlag;
/// _
__gshared int Py_UseClassExceptionsFlag;
/// _
__gshared int Py_FrozenFlag;
version(Python_3_0_Or_Later) {
}else{
    /// Availability: 2.*
    __gshared int Py_TabcheckFlag;
    /// Availability: 2.*
    __gshared int Py_UnicodeFlag;
}
/// _
__gshared int Py_IgnoreEnvironmentFlag;
/// _
__gshared int Py_DivisionWarningFlag;
version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    __gshared int Py_DontWriteBytecodeFlag;
    /// Availability: >= 2.6
    __gshared int Py_NoUserSiteDirectory;
}

version(Python_3_0_Or_Later) {
}else{
    /* _XXX Py_QnewFlag should go away in 3.0.  It's true iff -Qnew is passed,
       on the command line, and is used in 2.2 by ceval.c to make all "/" divisions
       true divisions (which they will be in 3.0). */
    /// Availability: 2.*
    __gshared int _Py_QnewFlag;

    version(Python_2_6_Or_Later) {
        /// Availability: 2.6, 2.7
        __gshared int Py_Py3kWarningFlag;
    }
}
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    __gshared int Py_UnbufferedStdioFlag;
}
version(Python_2_7_Or_Later) {
    /// Availability: >= 2.7
    __gshared int Py_HashRandomizationFlag;
}

/** this is a wrapper around getenv() that pays attention to
   Py_IgnoreEnvironmentFlag.  It should be used for getting variables like
   PYTHONPATH and PYTHONHOME from the environment */
char* Py_GETENV()(const(char)* s) {
    return (Py_IgnoreEnvironmentFlag ? null : getenv(s));
}

/// _
void Py_FatalError(const(char)* message);

