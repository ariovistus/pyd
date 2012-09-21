/**
  Mirror _pymem.h
  */
module deimos.python.pymem;

extern(C):
// Python-header-file: Include/pymem.h:
/// _
void* PyMem_Malloc(size_t);
/// _
void* PyMem_Realloc(void*, size_t);
/// _
void PyMem_Free(void*);


