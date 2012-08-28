module python2.ceval;

import python2.types;
import python2.object;
import python2.frameobject;
import python2.pystate;
import python2.pythonrun;

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

PyObject* PyEval_GetBuiltins();
PyObject* PyEval_GetGlobals();
PyObject* PyEval_GetLocals();
PyFrameObject *PyEval_GetFrame();
int PyEval_GetRestricted();

int PyEval_MergeCompilerFlags(PyCompilerFlags* cf);
int Py_FlushLine();
int Py_AddPendingCall(int function(void*) func, void* arg);
int Py_MakePendingCalls();

void Py_SetRecursionLimit(int);
int Py_GetRecursionLimit();

// The following API members are undocumented, so they're omitted here:
// Py_EnterRecursiveCall
// Py_LeaveRecursiveCall
// _Py_CheckRecursiveCall
// _Py_CheckRecursionLimit
// _Py_MakeRecCheck

Char1* PyEval_GetFuncName(PyObject*);
Char1* PyEval_GetFuncDesc(PyObject*);

PyObject* PyEval_GetCallStats(PyObject*);
PyObject* PyEval_EvalFrame(PyFrameObject*);
version(Python_2_5_Or_Later){
    PyObject* PyEval_EvalFrameEx(PyFrameObject*, int);
}

__gshared /*volatile*/ int _Py_Ticker;
__gshared int _Py_CheckInterval;

PyThreadState* PyEval_SaveThread();
void PyEval_RestoreThread(PyThreadState*);

