module deimos.python.pystrcmp;

import deimos.python.pyport;

version(Python_2_6_Or_Later) {
    int PyOS_mystrnicmp(const(char)*, const(char)*, Py_ssize_t);
    int PyOS_mystricmp(const(char)*, const(char)*);
}

