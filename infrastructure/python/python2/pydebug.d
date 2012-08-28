module python2.pydebug;

import std.c.stdlib;

extern(C):
// Python-header-file: Include/node.h

__gshared int Py_DebugFlag;
__gshared int Py_VerboseFlag;
__gshared int Py_InteractiveFlag;
__gshared int Py_OptimizeFlag;
__gshared int Py_NoSiteFlag;
__gshared int Py_UseClassExceptionsFlag;
__gshared int Py_FrozenFlag;
__gshared int Py_TabcheckFlag;
__gshared int Py_UnicodeFlag;
__gshared int Py_IgnoreEnvironmentFlag;
__gshared int Py_DivisionWarningFlag;
/* _XXX Py_QnewFlag should go away in 3.0.  It's true iff -Qnew is passed,
  on the command line, and is used in 2.2 by ceval.c to make all "/" divisions
  true divisions (which they will be in 3.0). */
__gshared int _Py_QnewFlag;

version(Python_2_6_Or_Later) {
    __gshared int Py_Py3kWarningFlag;
}

/* this is a wrapper around getenv() that pays attention to
   Py_IgnoreEnvironmentFlag.  It should be used for getting variables like
   PYTHONPATH and PYTHONHOME from the environment */
char* Py_GETENV()(const(char)* s) {
    return (Py_IgnoreEnvironmentFlag ? null : getenv(s));
}

void Py_FatalError(const(char)* message);

