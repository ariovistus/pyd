module python2.pymem;

extern(C):
// Python-header-file: Include/pymem.h:
void* PyMem_Malloc(size_t);
void* PyMem_Realloc(void*, size_t);
void PyMem_Free(void*);


