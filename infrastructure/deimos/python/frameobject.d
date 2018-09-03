/**
  Mirror _frameobject.h
  */
module deimos.python.frameobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.code;
import deimos.python.pystate;


extern(C):
// Python-header-file: Include/frameobject.h:

/// _
struct PyTryBlock {
    /** what kind of block this is */
    int b_type;
    /** where to jump to find handler */
    int b_handler;
    /** value stack level to pop to */
    int b_level;
}

/// subclass of PyVarObject
struct PyFrameObject {
    mixin PyObject_VAR_HEAD;

    /** previous frame, or NULL */
    PyFrameObject* f_back;
    /** code segment */
    PyCodeObject* f_code;
    /** builtin symbol table (PyDictObject) */
    PyObject* f_builtins;
    /** global symbol table (PyDictObject) */
    PyObject* f_globals;
    /** local symbol table (any mapping) */
    PyObject* f_locals;
    /** points after the last local */
    PyObject** f_valuestack;
    /** Next free slot in f_valuestack.  Frame creation sets to f_valuestack.
       Frame evaluation usually NULLs it, but a frame that yields sets it
       to the current stack top. */
    PyObject** f_stacktop;
    /** Trace function */
    PyObject* f_trace;

    version(Python_3_7_Or_Later) {
        /// Availability >= 3.7
        char f_trace_lines;
        /// Availability >= 3.7
        char f_trace_opcodes;
    }

    version(Python_3_7_Or_Later) {
    }else {
        /** If an exception is raised in this frame, the next three are used to
         * record the exception info (if any) originally in the thread state.  See
         * comments before set_exc_info() -- it's not obvious.
         * Invariant:  if _type is NULL, then so are _value and _traceback.
         * Desired invariant:  all three are NULL, or all three are non-NULL.  That
         * one isn't currently true, but "should be".
         */
        PyObject* f_exc_type;
        /// _
        PyObject* f_exc_value;
        /// _
        PyObject* f_exc_traceback;
    }
    version(Python_3_4_Or_Later) {
        /// _
        PyObject* f_gen;
    }else{
        /// _
        PyThreadState* f_tstate;
    }
    /** Last instruction if called */
    int f_lasti;
    /** Call PyFrame_GetLineNumber() instead of reading this field
       directly.  As of 2.3 f_lineno is only valid when tracing is
       active (i.e. when f_trace is set).  At other times we use
       PyCode_Addr2Line to calculate the line from the current
       bytecode index.

       Current line number
     */
    int f_lineno;
    version(Python_2_5_Or_Later){
    }else{
        /// Availability: 2.4
        int f_restricted;
    }
    /** index in f_blockstack */
    int f_iblock;
    version(Python_3_4_Or_Later) {
        char f_executing;
    }
    /** for try and loop blocks */
    PyTryBlock[CO_MAXBLOCKS] f_blockstack;
    version(Python_2_5_Or_Later){
    }else{
        /// Availability: 2.4
        int f_nlocals;
        /// ditto
        int f_ncells;
        /// ditto
        int f_nfreevars;
        /// ditto
        int f_stacksize;
    }
    PyObject*[1] _f_localsplus;
    /** locals+stack, dynamically sized */
    PyObject** f_localsplus()() {
        return _f_localsplus.ptr;
    }
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PyFrame_Type");

// D translation of C macro:
/// _
int PyFrame_Check()(PyObject* op) {
    return Py_TYPE(op) == &PyFrame_Type;
}
version(Python_3_0_Or_Later){
}else version(Python_2_5_Or_Later){
    /// Availability: 2.5, 2.6, 2.7
    int PyFrame_IsRestricted()(PyFrameObject* f) {
        return f.f_builtins != f.f_tstate.interp.builtins;
    }
}

/// _
PyFrameObject* PyFrame_New(PyThreadState*, PyCodeObject*,
        PyObject*, PyObject*);

/** Block management functions */
void PyFrame_BlockSetup(PyFrameObject*, int, int, int);
/// ditto
PyTryBlock* PyFrame_BlockPop(PyFrameObject*);
/** Extend the value stack */
PyObject** PyFrame_ExtendStack(PyFrameObject*, int, int);

/** Conversions between "fast locals" and locals in dictionary */
void PyFrame_LocalsToFast(PyFrameObject*, int);
/// ditto
void PyFrame_FastToLocals(PyFrameObject*);
version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    int PyFrame_ClearFreeList();
}
version(Python_2_7_Or_Later) {
    /** Return the line of code the frame is currently executing. */
    /// Availability: >= 2.7
    int PyFrame_GetLineNumber(PyFrameObject*);
}


