
//import pyd.pyd, pyd.embedded;
import std.range;
import std.c.stdio;
import std.algorithm;
import std.exception;
import python;
import std.stdio;

// PyObject_GetBuffer is causing a segfault somewhere, somehow.
void main() {
    Py_Initialize();
    PyObject* numpy_module = PyImport_ImportModule("numpy");
    PyObject* builtins = Py_INCREF(PyEval_GetBuiltins());
    PyObject* globals = PyDict_New();
    PyObject* builtin_str = PyString_FromString("__builtins__");
    PyDict_SetItem(globals, builtin_str, builtins);
    PyObject* locals = PyDict_New();

    PyObject* res = PyRun_String(
            "from numpy import eye\n"
            "a = eye(4)\n",
            Py_file_input,
            globals,
            locals);
    PyObject* a = Py_INCREF(PyDict_GetItem(locals, PyString_FromString("a")));
    printf("got result of eye(4), which is of type %s\n", a.ob_type.tp_name);
    if(PyObject_CheckBuffer(a)) {
        printf("a supports the new-style buffer interface!\n");
        printf("tp_as_buffer: %x\n", a.ob_type.tp_as_buffer);
        printf("bf_getbuffer: %x\n", &a.ob_type.tp_as_buffer.bf_getbuffer);

        Py_buffer buffer;
        if(PyObject_GetBuffer(a, &buffer, PyBUF_SIMPLE) != -1) {
            printf("PyObject_GetBuffer succeeded\n");
        }else{
            printf("PyObject_GetBuffer failed\n");
        }
    }

}
