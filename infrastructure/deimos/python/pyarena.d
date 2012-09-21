/**
  Mirrors _pyarena.h
  */
module deimos.python.pyarena;

import deimos.python.object;
// Python-header-file: Include/pyarena.h:
/// _
struct PyArena;

version(Python_2_5_Or_Later){
    /// Availability: >= 2.5
    PyArena* PyArena_New();
    /// Availability: >= 2.5
    void PyArena_Free(PyArena*);

    /// Availability: >= 2.5
    void* PyArena_Malloc(PyArena*, size_t);
    /// Availability: >= 2.5
    int PyArena_AddPyObject(PyArena*, PyObject*);
}

