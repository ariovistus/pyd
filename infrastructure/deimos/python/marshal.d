/**
  Mirror _marshal.h
  */
module deimos.python.marshal;

import core.stdc.stdio;
import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/marshal.h:

version(Python_2_5_Or_Later){
    /// _
    enum Py_MARSHAL_VERSION = 2;
} else version(Python_2_4_Or_Later){
    /// _
    enum Py_MARSHAL_VERSION = 1;
}

/// _
void PyMarshal_WriteLongToFile(C_long, FILE*, int);
/// _
void PyMarshal_WriteObjectToFile(PyObject*, FILE*, int);
/// _
PyObject* PyMarshal_WriteObjectToString(PyObject*, int);

/// _
C_long PyMarshal_ReadLongFromFile(FILE*);
/// _
int PyMarshal_ReadShortFromFile(FILE*);
/// _
PyObject* PyMarshal_ReadObjectFromFile(FILE*);
/// _
PyObject* PyMarshal_ReadLastObjectFromFile(FILE*);
/// _
PyObject* PyMarshal_ReadObjectFromString(char*, Py_ssize_t);


