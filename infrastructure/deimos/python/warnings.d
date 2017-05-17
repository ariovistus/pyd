/** Mirror warnings.h */

module deimos.python.warnings;

import deimos.python.pyport;
import deimos.python.object;

extern(C):

version(Python_3_4_Or_Later) {
    /// _
    int PyErr_WarnEx(
            PyObject* category,
            const (char)* message,
            Py_ssize_t stack_level);

    /// _
    int PyErr_WarnFormat(
            PyObject* category,
            Py_ssize_t stack_level,
            const (char)* format,
            ...);

    /// _
    int PyErr_WarnExplicit(
            PyObject* category,
            const(char)* message,
            const(char)* filename,
            int lineno,
            const(char)* module_,
            PyObject* registry);


}
version(Python_3_6_Or_Later) {
    /// _
    int PyErr_ResourceWarning(
            PyObject* source,
            Py_ssize_t stack_level,
            const(char)* format,
            ...);
}
