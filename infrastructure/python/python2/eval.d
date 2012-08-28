module python2.eval;

import python2.types;
import python2.object;
import python2.code;

extern(C):
// Python-header-file: Include/eval.h:
PyObject* PyEval_EvalCode(PyCodeObject*, PyObject*, PyObject*);
PyObject* PyEval_EvalCodeEx(
        PyCodeObject* co,
        PyObject* globals,
        PyObject* locals,
        PyObject** args, int argc,
        PyObject** kwds, int kwdc,
        PyObject** defs, int defc,
        PyObject* closure
);
PyObject* _PyEval_CallTracing(PyObject* func, PyObject* args);

