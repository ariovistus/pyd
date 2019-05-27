/**
  Mirror _pystate.h

  Thread and interpreter state structures and their interfaces
  */
module deimos.python.pystate;

import core.stdc.stddef : wchar_t;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.frameobject;
import deimos.python.pyatomic;
import deimos.python.moduleobject;
import deimos.python.pythread;

extern(C):
// Python-header-file: Include/pystate.h:

enum MAX_CO_EXTRA_USERS = 255;

version(Python_3_5_Or_Later) {
    alias PyObject* function(PyFrameObject*, int) _PyFrameEvalFunction;
}

version(Python_3_7_Or_Later) {
    struct _PyCoreConfig {
        int install_signal_handlers;  /* Install signal handlers? -1 means unset */

        int ignore_environment; /* -E, Py_IgnoreEnvironmentFlag */
        int use_hash_seed;      /* PYTHONHASHSEED=x */
        C_long hash_seed;
        char* allocator;  /* Memory allocator: _PyMem_SetupAllocators() */
        int dev_mode;           /* PYTHONDEVMODE, -X dev */
        int faulthandler;       /* PYTHONFAULTHANDLER, -X faulthandler */
        int tracemalloc;        /* PYTHONTRACEMALLOC, -X tracemalloc=N */
        int import_time;        /* PYTHONPROFILEIMPORTTIME, -X importtime */
        int show_ref_count;     /* -X showrefcount */
        int show_alloc_count;   /* -X showalloccount */
        int dump_refs;          /* PYTHONDUMPREFS */
        int malloc_stats;       /* PYTHONMALLOCSTATS */
        int coerce_c_locale;    /* PYTHONCOERCECLOCALE, -1 means unknown */
        int coerce_c_locale_warn; /* PYTHONCOERCECLOCALE=warn */
        int utf8_mode;          /* PYTHONUTF8, -X utf8; -1 means unknown */

        wchar_t* program_name;  /* Program name, see also Py_GetProgramName() */
        int argc;               /* Number of command line arguments,
                                   -1 means unset */
        wchar_t** argv;         /* Command line arguments */
        wchar_t* program;       /* argv[0] or "" */

        int nxoption;           /* Number of -X options */
        wchar_t** xoptions;     /* -X options */

        int nwarnoption;        /* Number of warnings options */
        wchar_t** warnoptions;  /* Warnings options */

        /* Path configuration inputs */
        wchar_t* module_search_path_env; /* PYTHONPATH environment variable */
        wchar_t* home;          /* PYTHONHOME environment variable,
                                   see also Py_SetPythonHome(). */
        /* Path configuration outputs */
        int nmodule_search_path;        /* Number of sys.path paths,
                                           -1 means unset */
        wchar_t** module_search_paths;  /* sys.path paths */
        wchar_t* executable;    /* sys.executable */
        wchar_t* prefix;        /* sys.prefix */
        wchar_t* base_prefix;   /* sys.base_prefix */
        wchar_t* exec_prefix;   /* sys.exec_prefix */
        wchar_t* base_exec_prefix;  /* sys.base_exec_prefix */

        /* Private fields */
        int _disable_importlib; /* Needed by freeze_importlib */
    }

    struct _PyMainInterpreterConfig{
        int install_signal_handlers;   /* Install signal handlers? -1 means unset */
        PyObject* argv;                /* sys.argv list, can be NULL */
        PyObject* executable;          /* sys.executable str */
        PyObject* prefix;              /* sys.prefix str */
        PyObject* base_prefix;         /* sys.base_prefix str, can be NULL */
        PyObject* exec_prefix;         /* sys.exec_prefix str */
        PyObject* base_exec_prefix;    /* sys.base_exec_prefix str, can be NULL */
        PyObject* warnoptions;         /* sys.warnoptions list, can be NULL */
        PyObject* xoptions;            /* sys._xoptions dict, can be NULL */
        PyObject* module_search_path;  /* sys.path list */
    }

    struct _PyErr_StackItem{
        /* This struct represents an entry on the exception stack, which is a
         * per-coroutine state. (Coroutine in the computer science sense,
         * including the thread and generators).
         * This ensures that the exception state is not impacted by "yields"
         * from an except handler.
         */
        PyObject* exc_type; 
        PyObject* exc_value; 
        PyObject* exc_traceback;

        _PyErr_StackItem* previous_item;

    }
}

/// _
struct PyInterpreterState {
    /// _
    PyInterpreterState* next;
    /// _
    PyThreadState* tstate_head;

    version(Python_3_7_Or_Later) {
        /// Availability >= 3.7
        long id;
        /// Availability >= 3.7
        long id_refcount;
        /// Availability >= 3.7
        PyThread_type_lock id_mutex;
    }
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

    version(Python_3_0_Or_Later) {
    }else version(Python_2_7_Or_Later) {
        /// Availability: 2.7 (?)
        PyObject* modules_reloading;
    }

    version(Python_3_3_Or_Later) {
        /// _
        PyObject* importlib;
    }
    version(Python_3_7_Or_Later) {
        /// _
        int check_interval;
        C_long num_threads;
        size_t pythread_stacksize;
    }

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

    version(Python_3_7_Or_Later) {
        _PyCoreConfig core_config;
        _PyMainInterpreterConfig config;
    }

    /// _
    int dlopenflags;

    // XXX: Not sure what WITH_TSC refers to, or how to conditionalize it in D:
    //#ifdef WITH_TSC
    //  int tscdump;
    //#endif

    version(Python_3_4_Or_Later) {
        PyObject* builtins_copy;
    }
    version(Python_3_6_Or_Later) {
        PyObject* import_func;
        _PyFrameEvalFunction eval_frame;
    }

    version(Python_3_7_Or_Later) {
        Py_ssize_t co_extra_user_count;
        freefunc[MAX_CO_EXTRA_USERS] co_extra_freefuncs;

        // ifdef HAVE_FORK
        PyObject* before_forkers;
        PyObject* after_forkers_parent;
        PyObject* after_forkers_child;
        // end ifdef HAVE_FORK

        void function(PyObject*) pyexitfunc;
        PyObject* pyexitmodule;

        ulong tstate_next_unique_id;

    }
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
    version(Python_3_4_Or_Later) {
        /// Availability: >= 3.4
        PyThreadState* prev;
    }
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
    version(Python_3_7_Or_Later) {
        /// _
        int stackcheck_counter;
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

    version(Python_3_7_Or_Later) {
        /// _
        _PyErr_StackItem exc_state;
        /// _
        _PyErr_StackItem* exc_info;
    }else{
        /// _
        PyObject* exc_type;
        /// _
        PyObject* exc_value;
        /// _
        PyObject* exc_traceback;
    }

    /// _
    PyObject* dict;

    version(Python_3_4_Or_Later) {
    }else{
        /** tick_counter is incremented whenever the check_interval ticker
         * reaches zero. The purpose is to give a useful measure of the number
         * of interpreted bytecode instructions in a given thread.  This
         * extremely lightweight statistic collector may be of interest to
         * profilers (like psyco.jit()), although nothing in the core uses it.
         */
        /// Availability: < 3.4
        int tick_counter;
    }
    /// _
    int gilstate_counter;
    /** Asynchronous exception to raise */
    PyObject* async_exc;
    /** Thread id where this tstate was created */
    C_long thread_id;

    version(Python_3_3_Or_Later) {
        /// Availability: >= 3.3
        int trash_delete_nesting;

        /// Availability: >= 3.3
        PyObject *trash_delete_later;
    }
    version(Python_3_4_Or_Later) {
        /// Availability: >= 3.4
        void function(void *) on_delete;
        /// Availability: >= 3.4
        void* on_delete_data;
    }
    version(Python_3_7_Or_Later) {
        int coroutine_origin_tracking_depth;
    }
    version(Python_3_5_Or_Later) {
        /// Availability: >= 3.5
        PyObject* coroutine_wrapper;
        /// Availability: >= 3.5
        int in_coroutine_wrapper;
    }

    version(Python_3_7_Or_Later) {
        PyObject* async_gen_firstiter;
        PyObject* async_gen_finalizer;

        PyObject* context;
        ulong context_ver;

        ulong id;
    }else version(Python_3_6_Or_Later) {
        /// Availability: = 3.6
        Py_ssize_t co_extra_user_count;
        /// Availability: = 3.6
        freefunc[MAX_CO_EXTRA_USERS] co_extra_freefuncs;
        /// Availability: >= 3.6
        PyObject* async_gen_firstiter;
        /// Availability: >= 3.6
        PyObject* async_gen_finalizer;
    }
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

version(Python_3_3_Or_Later) {
    /// _
    auto PyThreadState_GET()() {
        return PyThreadState_Get();
    }
} else version(Python_3_0_Or_Later) {
    /// _
    mixin(PyAPI_DATA!"_Py_atomic_address _PyThreadState_Current");

    /// _
    auto PyThreadState_GET()() {
        return cast(PyThreadState*)
                _Py_atomic_load_relaxed(&_PyThreadState_Current);
    }
} else {
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
