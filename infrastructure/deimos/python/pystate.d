/**
  Mirror _pystate.h

  Thread and interpreter state structures and their interfaces 
  */
module deimos.python.pystate;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.frameobject;
import deimos.python.pyatomic;
import deimos.python.moduleobject;

extern(C):
// Python-header-file: Include/pystate.h:

/// _
struct PyInterpreterState {
    /// _
    PyInterpreterState* next;
    /// _
    PyThreadState* tstate_head;

    /// _
    PyObject* modules;
    version(Python_3_0_Or_Later) {
        /// Availability: 3.*
        PyObject* modules_by_index;
    }
    /// _
    PyObject* sysdict;
    /// _
    PyObject* builtins;

    /// _
    PyObject* codec_search_path;
    /// _
    PyObject* codec_search_cache;
    /// _
    PyObject* codec_error_registry;
    version(Python_3_0_Or_Later) {
        /// Availability: 3.*
        int codecs_initialized;
        /// Availability: 3.*
        int fscodec_initialized;
    }

    /// _
    int dlopenflags;

    // XXX: Not sure what WITH_TSC refers to, or how to conditionalize it in D:
    //#ifdef WITH_TSC
    //  int tscdump;
    //#endif
}

/// _
alias int function(PyObject*, PyFrameObject*, int, PyObject*) Py_tracefunc;

/// _
enum PyTrace_CALL               = 0;
/// ditto
enum PyTrace_EXCEPTION          = 1;
/// ditto
enum PyTrace_LINE 		= 2;
/// ditto
enum PyTrace_RETURN 	        = 3;
/// ditto
enum PyTrace_C_CALL             = 4;
/// ditto
enum PyTrace_C_EXCEPTION        = 5;
/// ditto
enum PyTrace_C_RETURN           = 6;

/// _
struct PyThreadState {
    /// _
    PyThreadState* next;
    /// _
    PyInterpreterState* interp;

    /// _
    PyFrameObject* frame;
    /// _
    int recursion_depth;
    version(Python_3_0_Or_Later) {
        /** The stack has overflowed. Allow 50 more calls
           to handle the runtime error. */
        /// Availability: 3.*
        ubyte overflowed; 
        /** The current calls must not cause 
           a stack overflow. */
        /// Availability: 3.*
        ubyte recursion_critical; 
    }
    /// _
    int tracing;
    /// _
    int use_tracing;

    /// _
    Py_tracefunc c_profilefunc;
    /// _
    Py_tracefunc c_tracefunc;
    /// _
    PyObject* c_profileobj;
    /// _
    PyObject* c_traceobj;

    /// _
    PyObject* curexc_type;
    /// _
    PyObject* curexc_value;
    /// _
    PyObject* curexc_traceback;

    /// _
    PyObject* exc_type;
    /// _
    PyObject* exc_value;
    /// _
    PyObject* exc_traceback;

    /// _
    PyObject* dict;

    /** tick_counter is incremented whenever the check_interval ticker
     * reaches zero. The purpose is to give a useful measure of the number
     * of interpreted bytecode instructions in a given thread.  This
     * extremely lightweight statistic collector may be of interest to
     * profilers (like psyco.jit()), although nothing in the core uses it.
     */
    int tick_counter;
    /// _
    int gilstate_counter;
    /** Asynchronous exception to raise */
    PyObject* async_exc;
    /** Thread id where this tstate was created */
    C_long thread_id;
}

/// _
PyInterpreterState* PyInterpreterState_New();
/// _
void PyInterpreterState_Clear(PyInterpreterState *);
/// _
void PyInterpreterState_Delete(PyInterpreterState *);
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    int _PyState_AddModule(PyObject*, PyModuleDef*);
    /// Availability: 3.*
    PyObject* PyState_FindModule(PyModuleDef*);
}

/// _
PyThreadState* PyThreadState_New(PyInterpreterState *);
version(Python_2_6_Or_Later){
    /// Availability: >= 2.6
    PyThreadState * _PyThreadState_Prealloc(PyInterpreterState *);
    /// Availability: >= 2.6
    void _PyThreadState_Init(PyThreadState *);
}
/// _
void PyThreadState_Clear(PyThreadState *);
/// _
void PyThreadState_Delete(PyThreadState *);
/// _
void PyThreadState_DeleteCurrent();
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    void _PyGILState_Reinit();
}

/// _
PyThreadState* PyThreadState_Get();
/// _
PyThreadState* PyThreadState_Swap(PyThreadState*);
/// _
PyObject_BorrowedRef* PyThreadState_GetDict();
/// _
int PyThreadState_SetAsyncExc(C_long, PyObject*);

version(Python_3_0_Or_Later) {
    /// _
    mixin(PyAPI_DATA!"_Py_atomic_address _PyThreadState_Current");

    /// _
    auto PyThreadState_GET()() { 
        return cast(PyThreadState*)
                _Py_atomic_load_relaxed(&_PyThreadState_Current);
    }
}else{
    /// _
    mixin(PyAPI_DATA!"PyThreadState* _PyThreadState_Current");

    /// _
    auto PyThreadState_GET()() { 
        return _PyThreadState_Current;
    }
}

/// _
enum PyGILState_STATE {
    /// _
    PyGILState_LOCKED, 
    /// _
    PyGILState_UNLOCKED
};

/** Ensure that the current thread is ready to call the Python
   C API, regardless of the current state of Python, or of its
   thread lock.  This may be called as many times as desired
   by a thread so long as each call is matched with a call to
   PyGILState_Release().  In general, other thread-state APIs may
   be used between _Ensure() and _Release() calls, so long as the
   thread-state is restored to its previous state before the Release().
   For example, normal use of the Py_BEGIN_ALLOW_THREADS/
   Py_END_ALLOW_THREADS macros are acceptable.

   The return value is an opaque "handle" to the thread state when
   PyGILState_Ensure() was called, and must be passed to
   PyGILState_Release() to ensure Python is left in the same state. Even
   though recursive calls are allowed, these handles can *not* be shared -
   each unique call to PyGILState_Ensure must save the handle for its
   call to PyGILState_Release.

   When the function returns, the current thread will hold the GIL.

   Failure is a fatal error.
*/
PyGILState_STATE PyGILState_Ensure();

/** Release any resources previously acquired.  After this call, Python's
   state will be the same as it was prior to the corresponding
   PyGILState_Ensure() call (but generally this state will be unknown to
   the caller, hence the use of the GILState API.)

   Every call to PyGILState_Ensure must be matched by a call to
   PyGILState_Release on the same thread.
*/
void PyGILState_Release(PyGILState_STATE);

/** Helper/diagnostic function - get the current thread state for
   this thread.  May return NULL if no GILState API has been used
   on the current thread.  Note that the main thread always has such a
   thread-state, even if no auto-thread-state call has been made
   on the main thread.
*/
PyThreadState* PyGILState_GetThisThreadState();
/// _
PyInterpreterState* PyInterpreterState_Head();
/// _
PyInterpreterState* PyInterpreterState_Next(PyInterpreterState*);
/// _
PyThreadState* PyInterpreterState_ThreadHead(PyInterpreterState*);
/// _
PyThreadState* PyThreadState_Next(PyThreadState*);

/// _
alias PyFrameObject* function(PyThreadState* self_) PyThreadFrameGetter;

/// _
mixin(PyAPI_DATA!"PyThreadFrameGetter _PyThreadState_GetFrame");
