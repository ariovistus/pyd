/**
  Mirror _code.h

See_Also:
<a href="http://docs.python.org/c-api/code.html"> Code Objects </a>
  */

// TODO: does code.h really not exist in python 2.4?
module deimos.python.code;

import deimos.python.pyport;
import deimos.python.object;

extern(C):

/** Bytecode object

  subclass of PyObject.
 */
struct PyCodeObject {
    mixin PyObject_HEAD;

    /** #arguments, except *args */
    int co_argcount;
    version(Python_3_4_Or_Later) {
        /** #keyword only arguments */
        int co_kwonlyargcount;	
    }
    /** #local variables */
    int co_nlocals;
    /** #entries needed for evaluation stack */
    int co_stacksize;
    /** CO_..., see below */
    int co_flags;

    version(Python_3_6_Or_Later) {
        /** first source line number */
        int co_firstlineno;
    }

    /** instruction opcodes */
    PyObject* co_code;
    /** list (constants used) */
    PyObject* co_consts;
    /** list of strings (names used) */
    PyObject* co_names;
    /** tuple of strings (local variable names) */
    PyObject* co_varnames;
    /** tuple of strings (free variable names) */
    PyObject* co_freevars;
    /** tuple of strings (cell variable names) */
    PyObject* co_cellvars;

    version(Python_3_7_Or_Later) {
        Py_ssize_t *co_cell2arg;
    }else version(Python_3_3_Or_Later) {
        ubyte *co_cell2arg;
    }

    /** string (where it was loaded from) */
    PyObject* co_filename;
    /** string (name, for reference) */
    PyObject* co_name;
    version(Python_3_6_Or_Later) {
    }else{
        /** first source line number */
        int co_firstlineno;
    }
    /** string (encoding addr<->lineno mapping) See
       Objects/lnotab_notes.txt for details. */
    PyObject* co_lnotab;
    version(Python_2_5_Or_Later) {
        /** for optimization only (see frameobject.c) */
        /// Availability: >= 2.5
        void *co_zombieframe;
    }
    version(Python_2_7_Or_Later) {
        /** to support weakrefs to code objects */
        /// Availability: >= 2.7
        PyObject* co_weakreflist;
    }
    version(Python_3_6_Or_Later) {
        /** Scratch space for extra data relating to the code object.
          Type is a void* to keep the format private in codeobject.c to force
          people to go through the proper APIs */
        void* co_extra;
    }
}

/** Masks for co_flags above */
enum int CO_OPTIMIZED   = 0x0001;
/// ditto
enum int CO_NEWLOCALS   = 0x0002;
/// ditto
enum int CO_VARARGS     = 0x0004;
/// ditto
enum int CO_VARKEYWORDS = 0x0008;
/// ditto
enum int CO_NESTED      = 0x0010;
/// ditto
enum int CO_GENERATOR   = 0x0020;
/// ditto
enum int CO_NOFREE      = 0x0040;
version(Python_3_5_Or_Later) {
    /** The CO_COROUTINE flag is set for coroutine functions (defined with
       ``async def`` keywords) */
    enum int CO_COROUTINE   = 0x0080;
    /// _
    enum int CO_ITERABLE_COROUTINE      = 0x0100;
}

version(Python_2_5_Or_Later){
    // Removed in 2.5
}else{
    /// Availability: <= 2.5
    enum int CO_GENERATOR_ALLOWED      = 0x1000;
}
/// _
enum int CO_FUTURE_DIVISION        = 0x2000;
version(Python_2_5_Or_Later){
    /** do absolute imports by default */
    /// Availability: >= 2.5
    enum int CO_FUTURE_ABSOLUTE_IMPORT = 0x4000;
    /// Availability: >= 2.5
    enum int CO_FUTURE_WITH_STATEMENT  = 0x8000;
    /// ditto
    enum int CO_FUTURE_PRINT_FUNCTION  = 0x10000;
    /// ditto
    enum int CO_FUTURE_UNICODE_LITERALS  = 0x20000;
}
version(Python_3_2_Or_Later) {
    /// Availability: 3.2
    enum CO_FUTURE_BARRY_AS_BDFL =  0x40000;
}
version(Python_3_5_Or_Later) {
    /// Availability: 3.5
    enum CO_FUTURE_GENERATOR_STOP =  0x80000;
}

version(Python_3_5_Or_Later) {
    /// Availability: 3.7
    enum CO_FUTURE_ANNOTATIONS =  0x100000;
}

version(Python_3_7_Or_Later) {
    enum CO_CELL_NOT_AN_ARG = -1;
}else version(Python_3_2_Or_Later) {
    enum CO_CELL_NOT_AN_ARG = 255;
}

/** Max static block nesting within a function */
enum int CO_MAXBLOCKS = 20;

/// _
mixin(PyAPI_DATA!"PyTypeObject PyCode_Type");

// D translations of C macros:
/// _
int PyCode_Check()(PyObject* op) {
    return op.ob_type == &PyCode_Type;
}
/// _
size_t PyCode_GetNumFree()(PyObject* op) {
    return PyObject_Length((cast(PyCodeObject *) op).co_freevars);
}

/// _
PyCodeObject* PyCode_New(
        int argcount,
        int nlocals,
        int stacksize,
        int flags,
        PyObject* code,
        PyObject* consts,
        PyObject* names,
        PyObject* varnames,
        PyObject* freevars,
        PyObject* cellvars,
        PyObject* filenames,
        PyObject* name,
        int firstlineno,
        PyObject* lnotab);

version(Python_2_7_Or_Later) {
    /** Creates a new empty code object with the specified source location. */
    /// Availability: >= 2.7
    PyCodeObject* PyCode_NewEmpty(const(char)* filename,
            const(char)* funcname, int firstlineno);
}
/** Return the line number associated with the specified bytecode index
   in this code object.  If you just need the line number of a frame,
   use PyFrame_GetLineNumber() instead. */
int PyCode_Addr2Line(PyCodeObject *, int);

/// _
struct PyAddrPair {
    /// _
    int ap_lower;
    /// _
    int ap_upper;
}

version(Python_2_7_Or_Later) {
    /** Update *bounds to describe the first and one-past-the-last instructions in the
      same line as lasti.  Return the number of that line.
     */
    /// Availability: 2.7
    int _PyCode_CheckLineNumber(PyCodeObject* co,
                                        int lasti, PyAddrPair *bounds);
}else {
    /**Check whether lasti (an instruction offset) falls outside bounds
       and whether it is a line number that should be traced.  Returns
       a line number if it should be traced or -1 if the line should not.

       If lasti is not within bounds, updates bounds.
     */
    /// Availability: 2.5,2.6
    int PyCode_CheckLineNumber(PyCodeObject* co, int lasti, PyAddrPair *bounds);
}
version(Python_2_6_Or_Later){
    /// Availability: >= 2.6
    PyObject* PyCode_Optimize(PyObject* code, PyObject* consts,
            PyObject* names, PyObject* lineno_obj);
}
