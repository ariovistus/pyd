/**
  Mirror _pythread.h
  */
module deimos.python.pythread;

import deimos.python.pyport;

extern(C):
// Python-header-file: Include/pythread.h:

version(Python_3_2_Or_Later) {
    /** Return status codes for Python lock acquisition.  Chosen for maximum
     * backwards compatibility, ie failure -> 0, success -> 1.  */
    /// Availability: >= 3.2
    enum PyLockStatus {
        /// _
        PY_LOCK_FAILURE = 0,
        /// _
        PY_LOCK_ACQUIRED = 1,
        /// _
        PY_LOCK_INTR
    }
}

version(Python_3_7_Or_Later) {
    /// _
    enum PYTHREAD_INVALID_THREAD_ID = -1;
}

/// _
alias void* PyThread_type_lock;
/// _
alias void* PyThread_type_sema;

/// _
void PyThread_init_thread();
version(Python_3_7_Or_Later) {
    /// _
    C_ulong PyThread_start_new_thread(void function(void*), void*);
}else{
    /// _
    C_long PyThread_start_new_thread(void function(void*), void*);
}
/// _
void PyThread_exit_thread();
/// _
void PyThread__PyThread_exit_thread();
version(Python_3_7_Or_Later) {
    /// _
    C_ulong PyThread_get_thread_ident();
}else{
    /// _
    C_long PyThread_get_thread_ident();
}

/// _
PyThread_type_lock PyThread_allocate_lock();
/// _
void PyThread_free_lock(PyThread_type_lock);
/// _
int PyThread_acquire_lock(PyThread_type_lock, int);
/// _
enum WAIT_LOCK = 1;
/// _
enum NOWAIT_LOCK = 0;
version(Python_3_2_Or_Later) {
    /** PY_TIMEOUT_T is the integral type used to specify timeouts when waiting
       on a lock (see PyThread_acquire_lock_timed() below).
       PY_TIMEOUT_MAX is the highest usable value (in microseconds) of that
       type, and depends on the system threading API.

        NOTE: this isn't the same value as `_thread.TIMEOUT_MAX`.  The _thread
        module exposes a higher-level API, with timeouts expressed in seconds
        and floating-point numbers allowed.
     */
    /// Availability: >= 3.2
    alias C_long PY_TIMEOUT_T;

    /* In the NT API, the timeout is a DWORD and is expressed in milliseconds */
    /+ ??
#if defined (NT_THREADS)
#if (Py_LL(0xFFFFFFFF) * 1000 < PY_TIMEOUT_MAX)
#undef PY_TIMEOUT_MAX
#define PY_TIMEOUT_MAX (Py_LL(0xFFFFFFFF) * 1000)
#endif
#endif
        +/

        /* If microseconds == 0, the call is non-blocking: it returns immediately
       even when the lock can't be acquired.
       If microseconds > 0, the call waits up to the specified duration.
       If microseconds < 0, the call waits until success (or abnormal failure)

       microseconds must be less than PY_TIMEOUT_MAX. Behaviour otherwise is
       undefined.

       If intr_flag is true and the acquire is interrupted by a signal, then the
       call will return PY_LOCK_INTR.  The caller may reattempt to acquire the
       lock.
     */
    /// Availability: >= 3.2
        PyLockStatus PyThread_acquire_lock_timed(
            PyThread_type_lock,
            PY_TIMEOUT_T microseconds,
            int intr_flag);

}
/// _
void PyThread_release_lock(PyThread_type_lock);

version(Python_2_5_Or_Later){
    /// Availability: >= 2.5
    size_t PyThread_get_stacksize();
    /// Availability: >= 2.5
    int PyThread_set_stacksize(size_t);
}

/// _
void PyThread_exit_prog(int);
/// _
void PyThread__PyThread_exit_prog(int);

/// _
int PyThread_create_key();
/// _
void PyThread_delete_key(int);
/// _
int PyThread_set_key_value(int, void*);
/// _
void* PyThread_get_key_value(int);
/// _
void PyThread_delete_key_value(int key);

version(Python_2_5_Or_Later) {
    /// Availability: >= 2.5
    void PyThread_ReInitTLS();
}

version(Python_3_7_Or_Later) {
    version(Posix) {
        import core.sys.posix.pthread;

        alias pthread_key_t NATIVE_TSS_KEY_T;
    }else {
        alias C_ulong NATIVE_TSS_KEY_T;
    }

    struct Py_tss_t {
        int _is_initialized;
        NATIVE_TSS_KEY_T _key;
    }

    enum Py_tss_NEEDS_INIT = 0;

    Py_tss_t* PyThread_tss_alloc();
    void PyThread_tss_free(Py_tss_t* key);

    int PyThread_tss_is_created(Py_tss_t* key);
    int PyThread_tss_create(Py_tss_t* key);
    void PyThread_tss_delete(Py_tss_t* key);
    int PyThread_tss_set(Py_tss_t* key, void* value);
    void* PyThread_tss_get(Py_tss_t* key);
}
