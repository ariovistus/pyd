module python2.marshal;

import std.c.stdio;
import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/marshal.h:

version(Python_2_5_Or_Later){
    enum Py_MARSHAL_VERSION = 2;
} else version(Python_2_4_Or_Later){
    enum Py_MARSHAL_VERSION = 1;
}

void PyMarshal_WriteLongToFile(C_long, FILE*, int);
void PyMarshal_WriteObjectToFile(PyObject*, FILE*, int);
PyObject* PyMarshal_WriteObjectToString(PyObject*, int);

C_long PyMarshal_ReadLongFromFile(FILE*);
int PyMarshal_ReadShortFromFile(FILE*);
PyObject* PyMarshal_ReadObjectFromFile(FILE*);
PyObject* PyMarshal_ReadLastObjectFromFile(FILE*);
PyObject* PyMarshal_ReadObjectFromString(char*, Py_ssize_t);


