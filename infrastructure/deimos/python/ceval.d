module deimos.python.ceval;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.frameobject;
import deimos.python.pystate;
import deimos.python.pythonrun;

extern(C):
// Python-header-file: Include/ceval.h:

PyObject* PyEval_CallObjectWithKeywords(PyObject* , PyObject* , PyObject* );
version(Python_2_5_Or_Later){
    PyObject* PyEval_CallObject()(PyObject* func, PyObject* arg) {
        return PyEval_CallObjectWithKeywords(func, arg, null);
    }
}else{
    PyObject* PyEval_CallObject(PyObject* , PyObject* );
}
PyObject* PyEval_CallFunction(PyObject* obj, Char1* format, ...);
PyObject* PyEval_CallMethod(PyObject* obj, Char1* methodname, Char1* format, ...);

void PyEval_SetProfile(Py_tracefunc, PyObject*);
void PyEval_SetTrace(Py_tracefunc, PyObject*);

Borrowed!PyObject* PyEval_GetBuiltins();
Borrowed!PyObject* PyEval_GetGlobals();
Borrowed!PyObject* PyEval_GetLocals();
Borrowed!PyFrameObject* PyEval_GetFrame();
version(Python_3_0_Or_Later) {
}else {
    int PyEval_GetRestricted();
    int Py_FlushLine();
}

int PyEval_MergeCompilerFlags(PyCompilerFlags* cf);
int Py_AddPendingCall(int function(void*) func, void* arg);
int Py_MakePendingCalls();

void Py_SetRecursionLimit(int);
int Py_GetRecursionLimit();

// d translation of c macro:
int Py_EnterRecursiveCall()(char* where) {
    return _Py_MakeRecCheck(PyThreadState_GET().recursion_depth) &&  
        _Py_CheckRecursiveCall(where);
}
void Py_LeaveRecursiveCall()() {
    version(Python_3_0_Or_Later) {
        if(_Py_MakeEndRecCheck(PyThreadState_GET().recursion_depth))
            PyThreadState_GET()->overflowed = 0;  
    }else {
        --PyThreadState_GET().recursion_depth;
    }
}
int _Py_CheckRecursiveCall(char* where);
__gshared int _Py_CheckRecursionLimit;

// TODO: version(STACKCHECK)
int _Py_MakeRecCheck()(int x) {
    return (++(x) > _Py_CheckRecursionLimit);
}

version(Python_3_0_Or_Later) {
    // d translation of c macro:
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

    /// meant to be mixed in
    string Py_ALLOW_RECURSION()(string inner_code) {
        import std.array;
        return replace(q{
                {
                ubyte _old = PyThreadState_GET()->recursion_critical;
                PyThreadState_GET()->recursion_critical = 1;
                $inner_code;
                PyThreadState_GET()->recursion_critical = _old; 
                }
        }, "$inner_code", inner_code);
    }
}

Char1* PyEval_GetFuncName(PyObject*);
Char1* PyEval_GetFuncDesc(PyObject*);

PyObject* PyEval_GetCallStats(PyObject*);
PyObject* PyEval_EvalFrame(PyFrameObject*);
version(Python_2_5_Or_Later){
    PyObject* PyEval_EvalFrameEx(PyFrameObject*, int);
}

version(Python_3_0_Or_Later) {
}else{
    __gshared /*volatile*/ int _Py_Ticker;
    __gshared int _Py_CheckInterval;
}

PyThreadState* PyEval_SaveThread();
void PyEval_RestoreThread(PyThreadState*);

// version(WITH_THREAD) assumed?
int PyEval_ThreadsInitialized();
void PyEval_InitThreads();
version(Python_3_0_Or_Later) {
    void _PyEval_FiniThreads();
}
void PyEval_AcquireLock();
void PyEval_ReleaseLock();
void PyEval_AcquireThread(PyThreadState* tstate);
void PyEval_ReleaseThread(PyThreadState* tstate);
void PyEval_ReInitThreads();

version(Python_3_0_Or_Later) {
    void _PyEval_SetSwitchInterval(C_ulong microseconds);
    C_ulong _PyEval_GetSwitchInterval();
}

/* ??
#define Py_BLOCK_THREADS        PyEval_RestoreThread(_save);
#define Py_UNBLOCK_THREADS      _save = PyEval_SaveThread();
*/
/// Py_BEGIN_ALLOW_THREADS inner_code Py_END_ALLOW_THREADS
/// meant to be mixed in.
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

int _PyEval_SliceIndex(PyObject*, Py_ssize_t*);
version(Python_3_0_Or_Later) {
    void _PyEval_SignalAsyncExc();
}
