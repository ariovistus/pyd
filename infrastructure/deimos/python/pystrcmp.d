/**
  Mirror _pystrcp.h
  */
module deimos.python.pystrcmp;

import deimos.python.pyport;

version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    int PyOS_mystrnicmp(const(char)*, const(char)*, Py_ssize_t);
    /// Availability: >= 2.6
    int PyOS_mystricmp(const(char)*, const(char)*);
}

