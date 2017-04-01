/**
  Mirror osmodule.h
  */

module deimos.python.osmodule;

import deimos.python.pyport;
import deimos.python.object;

extern(C):

    version(Python_3_6_Or_Later) {
        PyObject* PyOs_FSPath(PyObject* path);
    }
