/**
  Mirror _pymem.h
  */
module deimos.python.pymem;

import core.stdc.stdint;

extern(C):
// Python-header-file: Include/pymem.h:

version(Python_3_7_Or_Later) {
    int PyTraceMalloc_Track(
        uint domain,
        uintptr_t ptr,
        size_t size);

    int PyTraceMalloc_Untrack(
        uint domain,
        uintptr_t ptr);
}
/// _
void* PyMem_Malloc(size_t);
version(Python_3_5_Or_Later) {
    /// _
    void* PyMem_Calloc(size_t, size_t);
}
/// _
void* PyMem_Realloc(void*, size_t);
/// _
void PyMem_Free(void*);


