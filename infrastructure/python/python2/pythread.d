module python2.pythread;

import python2.types;

extern(C):
// Python-header-file: Include/pythread.h:

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

