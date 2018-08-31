/**
  Mirror _ceval.h
  */
module deimos.python.ceval;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.frameobject;
import deimos.python.pystate;
import deimos.python.pythonrun;
import deimos.python.compile;

extern(C):
// Python-header-file: Include/ceval.h:

/// _
PyObject* PyEval_CallObjectWithKeywords(
        PyObject* func, PyObject* args, PyObject* kwargs);

version(Python_2_5_Or_Later){
    /// _
    PyObject* PyEval_CallObject()(PyObject* func, PyObject* arg) {
        return PyEval_CallObjectWithKeywords(func, arg, null);
    }
}else{
    /// _
    PyObject* PyEval_CallObject(PyObject* , PyObject* );
}
/// _
PyObject* PyEval_CallFunction(PyObject* obj, const(char)* format, ...);
/// _
PyObject* PyEval_CallMethod(
        PyObject* obj,
        const(char)* methodname,
        const(char)* format, ...);

/// _
void PyEval_SetProfile(Py_tracefunc, PyObject*);
/// _
void PyEval_SetTrace(Py_tracefunc, PyObject*);
/// _
Borrowed!PyObject* PyEval_GetBuiltins();
/// _
Borrowed!PyObject* PyEval_GetGlobals();
/// _
Borrowed!PyObject* PyEval_GetLocals();
/// _
Borrowed!PyFrameObject* PyEval_GetFrame();
version(Python_3_0_Or_Later) {
}else {
    /// Availability: 2.*
    int PyEval_GetRestricted();
    /// Availability: 2.*
    int Py_FlushLine();
}

/** Look at the current frame's (if any) code's co_flags, and turn on
   the corresponding compiler flags in cf->cf_flags.  Return 1 if any
   flag was set, else return 0. */
int PyEval_MergeCompilerFlags(PyCompilerFlags* cf);
/// _
int Py_AddPendingCall(int function(void*) func, void* arg);
/// _
int Py_MakePendingCalls();
/// _
void Py_SetRecursionLimit(int);
/// _
int Py_GetRecursionLimit();

// d translation of c macro:
/// _
int Py_EnterRecursiveCall()(char* where) {
    return _Py_MakeRecCheck(PyThreadState_GET().recursion_depth) &&
        _Py_CheckRecursiveCall(where);
}
/// _
void Py_LeaveRecursiveCall()() {
    version(Python_3_0_Or_Later) {
        if(_Py_MakeEndRecCheck(PyThreadState_GET().recursion_depth))
            PyThreadState_GET().overflowed = 0;
    }else {
        --PyThreadState_GET().recursion_depth;
    }
}
/// _
int _Py_CheckRecursiveCall(char* where);
/// _
mixin(PyAPI_DATA!"int _Py_CheckRecursionLimit");

// TODO: version(STACKCHECK)
/// _
int _Py_MakeRecCheck()(int x) {
    return (++(x) > _Py_CheckRecursionLimit);
}

version(Python_3_0_Or_Later) {
    // d translation of c macro:
    /// Availability: 3.*
    auto _Py_MakeEndRecCheck()(x) {
        return (--(x) < ((_Py_CheckRecursionLimit > 100)
                    ? (_Py_CheckRecursionLimit - 50)
                    : (3 * (_Py_CheckRecursionLimit >> 2))));
    }
    /*
    auto Py_ALLOW_RECURSION()() {
        do{
        ubyte _old = PyThreadState_GET()->recursion_critical;
        PyThreadState_GET()->recursion_critical = 1;
    }

    auto Py_END_ALLOW_RECURSION()() {
        PyThreadState_GET()->recursion_critical = _old;
        }while(0);
    }
    */

    /**
      D's answer to C's
      ---
      Py_ALLOW_RECURSION
      ..code..
      Py_END_ALLOW_RECURSION
      ---

      is
      ---
      mixin(Py_ALLOW_RECURSION(q{
        ..code..
      }));
      ---
      */
    string Py_ALLOW_RECURSION()(string inner_code) {
        import std.array;
        return replace(q{
                {
                ubyte _old = PyThreadState_GET().recursion_critical;
                PyThreadState_GET().recursion_critical = 1;
                $inner_code;
                PyThreadState_GET().recursion_critical = _old;
                }
        }, "$inner_code", inner_code);
    }
}

/// _
const(char)* PyEval_GetFuncName(PyObject*);
/// _
const(char)* PyEval_GetFuncDesc(PyObject*);

version(Python_3_7_Or_Later) {
}else{
    /// _
    PyObject* PyEval_GetCallStats(PyObject*);
}
/// _
PyObject* PyEval_EvalFrame(PyFrameObject*);
version(Python_2_5_Or_Later){
    /// Availability: >= 2.5
    PyObject* PyEval_EvalFrameEx(PyFrameObject*, int);
}

version(Python_3_0_Or_Later) {
}else{
    /// _
    mixin(PyAPI_DATA!"/*volatile*/ int _Py_Ticker");
    /// _
    mixin(PyAPI_DATA!"int _Py_CheckInterval");
}

/// _
PyThreadState* PyEval_SaveThread();
/// _
void PyEval_RestoreThread(PyThreadState*);

// version(WITH_THREAD) assumed?
/// _
int PyEval_ThreadsInitialized();
/// _
void PyEval_InitThreads();
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    void _PyEval_FiniThreads();
}
/// _
void PyEval_AcquireLock();
/// _
void PyEval_ReleaseLock();
/// _
void PyEval_AcquireThread(PyThreadState* tstate);
/// _
void PyEval_ReleaseThread(PyThreadState* tstate);
/// _
void PyEval_ReInitThreads();

version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    void _PyEval_SetSwitchInterval(C_ulong microseconds);
    /// Availability: 3.*
    C_ulong _PyEval_GetSwitchInterval();
}

/* ??
#define Py_BLOCK_THREADS        PyEval_RestoreThread(_save);
#define Py_UNBLOCK_THREADS      _save = PyEval_SaveThread();
*/

/**
  D's answer to C's
  ---
  Py_BEGIN_ALLOW_THREADS
  ..code..
  Py_END_ALLOW_THREADS
  ---
  is
  ---
  mixin(Py_ALLOW_THREADS(q{
  ..code..
  }));
  ---
  */
string Py_ALLOW_THREADS()(string inner_code) {
    import std.array;
    return replace(q{
            {
            PyThreadState* _save = PyEval_SaveThread();
            $inner_code;
            PyEval_RestoreThread(_save);
            }
    }, "$inner_code", inner_code);
}

///_
int _PyEval_SliceIndex(PyObject*, Py_ssize_t*);
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    void _PyEval_SignalAsyncExc();
}
