module python2.structseq;

import python2.types;
import python2.object;

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

// XXX: What about global var PyStructSequence_UnnamedField?

void PyStructSequence_InitType(PyTypeObject* type, PyStructSequence_Desc* desc);
PyObject *PyStructSequence_New(PyTypeObject* type);

struct PyStructSequence {
    mixin PyObject_VAR_HEAD;
    // DSR:XXX:LAYOUT:
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


