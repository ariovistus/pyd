/**
  Mirror _pydebug.h
  */
module deimos.python.pydebug;

import core.stdc.stdlib;

import deimos.python.pyport;

extern(C):
// Python-header-file: Include/node.h

/// _
mixin(PyAPI_DATA!"int Py_DebugFlag");
/// _
mixin(PyAPI_DATA!"int Py_VerboseFlag");
version(Python_3_0_Or_Later) {
    mixin(PyAPI_DATA!"int Py_QuietFlag");
}
/// _
mixin(PyAPI_DATA!"int Py_InteractiveFlag");
/// _
mixin(PyAPI_DATA!"int Py_OptimizeFlag");
/// _
mixin(PyAPI_DATA!"int Py_NoSiteFlag");

version(Python_3_7_Or_Later) {
}else{
    /// _
    mixin(PyAPI_DATA!"int Py_UseClassExceptionsFlag");
}

/// _
mixin(PyAPI_DATA!"int Py_FrozenFlag");
version(Python_3_0_Or_Later) {
}else{
    /// Availability: 2.*
    mixin(PyAPI_DATA!"int Py_TabcheckFlag");
    /// Availability: 2.*
    mixin(PyAPI_DATA!"int Py_UnicodeFlag");
}
/// _
mixin(PyAPI_DATA!"int Py_IgnoreEnvironmentFlag");
/// _
mixin(PyAPI_DATA!"int Py_DivisionWarningFlag");
version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    mixin(PyAPI_DATA!"int Py_DontWriteBytecodeFlag");
    /// Availability: >= 2.6
    mixin(PyAPI_DATA!"int Py_NoUserSiteDirectory");
}

version(Python_3_0_Or_Later) {
}else{
    /* _XXX Py_QnewFlag should go away in 3.0.  It's true iff -Qnew is passed,
       on the command line, and is used in 2.2 by ceval.c to make all "/" divisions
       true divisions (which they will be in 3.0). */
    /// Availability: 2.*
    mixin(PyAPI_DATA!"int _Py_QnewFlag");

    version(Python_2_6_Or_Later) {
        /// Availability: 2.6, 2.7
        mixin(PyAPI_DATA!"int Py_Py3kWarningFlag");
    }
}
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    mixin(PyAPI_DATA!"int Py_UnbufferedStdioFlag");
}
version(Python_2_7_Or_Later) {
    /// Availability: >= 2.7
    mixin(PyAPI_DATA!"int Py_HashRandomizationFlag");
}

version(Python_3_4_Or_Later) {
    /// Availability: >= 3.4
    mixin(PyAPI_DATA!"int Py_IsolatedFlag");
}

version(Windows) {
    version(Python_3_7_Or_Later) {
        mixin(PyAPI_DATA!"int Py_LegacyWindowsFSEncodingFlag");
    }
    version(Python_3_6_Or_Later) {
        mixin(PyAPI_DATA!"int Py_LegacyWindowsStdioFlag");
    }
}

/** this is a wrapper around getenv() that pays attention to
   Py_IgnoreEnvironmentFlag.  It should be used for getting variables like
   PYTHONPATH and PYTHONHOME from the environment */
char* Py_GETENV()(const(char)* s) {
    return (Py_IgnoreEnvironmentFlag ? null : getenv(s));
}

/// _
void Py_FatalError(const(char)* message);

