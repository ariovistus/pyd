/**
  Mirror _eval.h
  */
module deimos.python.eval;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.code;

extern(C):
// Python-header-file: Include/eval.h:
/// _
PyObject* PyEval_EvalCode(PyCodeObject*, PyObject*, PyObject*);
/// _
PyObject* PyEval_EvalCodeEx(
        PyCodeObject* co,
        PyObject* globals,
        PyObject* locals,
        PyObject** args, int argc,
        PyObject** kwds, int kwdc,
        PyObject** defs, int defc,
        PyObject* closure
);
/// _
PyObject* _PyEval_CallTracing(PyObject* func, PyObject* args);

