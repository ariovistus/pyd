/**
  Mirror internal/hamt.h

  */

module deimos.python.internal.hamt;

import deimos.python.pyport;
import deimos.python.object;

extern(C): version(Python_3_7_Or_Later):
    enum _Py_HAMT_MAX_TREE_DEPTH = 7;

    struct PyHamtNode {
        mixin PyObject_HEAD!();
    }

    struct PyHamtObject {
        mixin PyObject_HEAD!();
        PyHamtNode* h_root;
        PyObject* h_weakreflist;
        Py_ssize_t h_count;
    }

    struct PyHamtIteratorState {
        PyHamtNode*[_Py_HAMT_MAX_TREE_DEPTH] i_nodes;
        Py_ssize_t[_Py_HAMT_MAX_TREE_DEPTH] i_pos;
        byte i_level;
    }

    struct PyHamtIterator {
        mixin PyObject_HEAD!();
        PyHamtObject* hi_obj;
        PyHamtIteratorState hi_iter;
        binaryfunc hi_yield;
    }
