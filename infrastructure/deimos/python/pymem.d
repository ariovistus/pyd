/**
  Mirror _pymem.h
  */
module deimos.python.pymem;

extern(C):
// Python-header-file: Include/pymem.h:
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


