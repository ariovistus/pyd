/**
  Mirror _structseq.h

  Tuple object interface
*/
module deimos.python.structseq;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.tupleobject;

extern(C):
// Python-header-file: Include/structseq.h:

/// _
struct PyStructSequence_Field {
    /// _
    char* name;
    /// _
    char* doc;
}

/// _
struct PyStructSequence_Desc {
    /// _
    char* name;
    /// _
    char* doc;
    /// _
    PyStructSequence_Field* fields;
    /// _
    int n_in_sequence;
}

/// _
void PyStructSequence_InitType(PyTypeObject* type, PyStructSequence_Desc* desc);
version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    PyTypeObject* PyStructSequence_NewType(PyStructSequence_Desc* desc);
}
/// _
PyObject* PyStructSequence_New(PyTypeObject* type);

version(Python_3_2_Or_Later) {
    /// _
    alias PyTupleObject PyStructSequence;
    /// _
    alias PyTuple_SET_ITEM PyStructSequence_SET_ITEM;

    /// Availability: >= 3.2
    void PyStructSequence_SetItem(PyObject*, Py_ssize_t, PyObject*);
    /// Availability: >= 3.2
    PyObject* PyStructSequence_GetItem(PyObject*, Py_ssize_t);
}else{
    /// _
    struct PyStructSequence {
        mixin PyObject_VAR_HEAD;
        // Will the D layout for a 1-obj array be the same as the C layout?  I
        // think the D array will be larger.
        PyObject*[1] _ob_item;
        /// _
        PyObject** ob_item()() {
            return _ob_item.ptr;
        }
    }
    // D translation of C macro:
    /** Macro, *only* to be used to fill in brand new objects */
    PyObject* PyStructSequence_SET_ITEM()(PyObject* op, int i, PyObject* v) {
        PyStructSequence* ot = cast(PyStructSequence*) op;
        ot.ob_item[i] = v;
        return v;
    }
}