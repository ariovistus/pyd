module deimos.python.structseq;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.tupleobject;

extern(C):
// Python-header-file: Include/structseq.h:

struct PyStructSequence_Field {
    char* name;
    char* doc;
}

struct PyStructSequence_Desc {
    char* name;
    char* doc;
    PyStructSequence_Field *fields;
    int n_in_sequence;
}

void PyStructSequence_InitType(PyTypeObject* type, PyStructSequence_Desc* desc);
version(Python_3_2_Or_Later) {
    PyTypeObject* PyStructSequence_NewType(PyStructSequence_Desc* desc);
}
PyObject *PyStructSequence_New(PyTypeObject* type);

version(Python_3_2_Or_Later) {
    alias PyTupleObject PyStructSequence;
    alias PyTuple_SET_ITEM PyStructSequence_SET_ITEM;

    void PyStructSequence_SetItem(PyObject*, Py_ssize_t, PyObject*);
    PyObject* PyStructSequence_GetItem(PyObject*, Py_ssize_t);
}else{ 
    struct PyStructSequence {
        mixin PyObject_VAR_HEAD;
        // Will the D layout for a 1-obj array be the same as the C layout?  I
        // think the D array will be larger.
        PyObject *_ob_item[1];
        PyObject** ob_item()() {
            return _ob_item.ptr;
        }
    }
    // D translation of C macro:
    PyObject *PyStructSequence_SET_ITEM()(PyObject* op, int i, PyObject* v) {
        PyStructSequence* ot = cast(PyStructSequence*) op;
        ot.ob_item[i] = v;
        return v;
    }
}



