module deimos.python.pythread;

import deimos.python.pyport;

extern(C):
// Python-header-file: Include/pythread.h:

version(Python_3_2_Or_Later) {
    /* Return status codes for Python lock acquisition.  Chosen for maximum
     * backwards compatibility, ie failure -> 0, success -> 1.  */
    enum PyLockStatus {
        PY_LOCK_FAILURE = 0,
        PY_LOCK_ACQUIRED = 1,
        PY_LOCK_INTR
    } 
}

alias void* PyThread_type_lock;
alias void* PyThread_type_sema;

void PyThread_init_thread();
C_long PyThread_start_new_thread(void function(void*), void*);
void PyThread_exit_thread();
void PyThread__PyThread_exit_thread();
C_long PyThread_get_thread_ident();

PyThread_type_lock PyThread_allocate_lock();
void PyThread_free_lock(PyThread_type_lock);
int PyThread_acquire_lock(PyThread_type_lock, int);
enum WAIT_LOCK = 1;
enum NOWAIT_LOCK = 0;
version(Python_3_2_Or_Later) {
    /* PY_TIMEOUT_T is the integral type used to specify timeouts when waiting
       on a lock (see PyThread_acquire_lock_timed() below).
       PY_TIMEOUT_MAX is the highest usable value (in microseconds) of that
       type, and depends on the system threading API.

        NOTE: this isn't the same value as `_thread.TIMEOUT_MAX`.  The _thread
        module exposes a higher-level API, with timeouts expressed in seconds
        and floating-point numbers allowed.
     */
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
        PyLockStatus PyThread_acquire_lock_timed(
            PyThread_type_lock,
            PY_TIMEOUT_T microseconds,
            int intr_flag);

}
void PyThread_release_lock(PyThread_type_lock);

version(Python_2_5_Or_Later){
    size_t PyThread_get_stacksize();
    int PyThread_set_stacksize(size_t);
}

void PyThread_exit_prog(int);
void PyThread__PyThread_exit_prog(int);

int PyThread_create_key();
void PyThread_delete_key(int);
int PyThread_set_key_value(int, void*);
void* PyThread_get_key_value(int);
void PyThread_delete_key_value(int key);

version(Python_2_5_Or_Later) {
    void PyThread_ReInitTLS();
}

