module python2.pystate;

import python2.types;
import python2.object;
import python2.frameobject;

extern(C):
// Python-header-file: Include/pystate.h:

struct PyInterpreterState {
    PyInterpreterState* next;
    PyThreadState* tstate_head;

    PyObject* modules;
    PyObject* sysdict;
    PyObject* builtins;

    PyObject* codec_search_path;
    PyObject* codec_search_cache;
    PyObject* codec_error_registry;

    int dlopenflags;

    // XXX: Not sure what WITH_TSC refers to, or how to conditionalize it in D:
    //#ifdef WITH_TSC
    //  int tscdump;
    //#endif
}

alias int function(PyObject*, PyFrameObject*, int, PyObject*) Py_tracefunc;

enum PyTrace_CALL               = 0;
enum PyTrace_EXCEPTION          = 1;
enum PyTrace_LINE 		= 2;
enum PyTrace_RETURN 	        = 3;
enum PyTrace_C_CALL             = 4;
enum PyTrace_C_EXCEPTION        = 5;
enum PyTrace_C_RETURN           = 6;

struct PyThreadState {
    PyThreadState* next;
    PyInterpreterState* interp;

    PyFrameObject* frame;
    int recursion_depth;
    int tracing;
    int use_tracing;

    Py_tracefunc c_profilefunc;
    Py_tracefunc c_tracefunc;
    PyObject* c_profileobj;
    PyObject* c_traceobj;

    PyObject* curexc_type;
    PyObject* curexc_value;
    PyObject* curexc_traceback;

    PyObject* exc_type;
    PyObject* exc_value;
    PyObject* exc_traceback;

    PyObject* dict;

    int tick_counter;
    int gilstate_counter;

    PyObject* async_exc;
    C_long thread_id;
}

PyInterpreterState* PyInterpreterState_New();
void PyInterpreterState_Clear(PyInterpreterState *);
void PyInterpreterState_Delete(PyInterpreterState *);

PyThreadState* PyThreadState_New(PyInterpreterState *);
version(Python_2_6_Or_Later){
    PyThreadState * _PyThreadState_Prealloc(PyInterpreterState *);
    void _PyThreadState_Init(PyThreadState *);
}
void PyThreadState_Clear(PyThreadState *);
void PyThreadState_Delete(PyThreadState *);
void PyThreadState_DeleteCurrent();

PyThreadState* PyThreadState_Get();
PyThreadState* PyThreadState_Swap(PyThreadState*);
PyObject_BorrowedRef* PyThreadState_GetDict();
int PyThreadState_SetAsyncExc(C_long, PyObject*);

__gshared PyThreadState* _PyThreadState_Current;

enum PyGILState_STATE {PyGILState_LOCKED, PyGILState_UNLOCKED};

PyGILState_STATE PyGILState_Ensure();
void PyGILState_Release(PyGILState_STATE);
PyThreadState* PyGILState_GetThisThreadState();
PyInterpreterState* PyInterpreterState_Head();
PyInterpreterState* PyInterpreterState_Next(PyInterpreterState*);
PyThreadState* PyInterpreterState_ThreadHead(PyInterpreterState*);
PyThreadState* PyThreadState_Next(PyThreadState*);

alias PyFrameObject* function(PyThreadState* self_) PyThreadFrameGetter;

__gshared PyThreadFrameGetter _PyThreadState_GetFrame;
