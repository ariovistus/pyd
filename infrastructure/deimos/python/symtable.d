/**
  Mirror _symtable.h
  */
module deimos.python.symtable;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.compile;
import deimos.python.ast;
import deimos.python.node;

extern(C):

/// _
struct _symtable_entry;

version(Python_2_5_Or_Later) {
    /// Availability: >= 2.5
    enum _Py_block_ty{
        /// _
        FunctionBlock,
        /// _
        ClassBlock,
        /// _
        ModuleBlock
    }
}

/// _
struct symtable {
    version(Python_2_5_Or_Later) {
    }else{
        /** pass == 1 or 2 */
        /// Availability: 2.4
        int st_pass;
    }
    /** name of file being compiled */
    const(char)*st_filename;
    /** current symbol table entry */
    _symtable_entry* st_cur;
    version(Python_2_5_Or_Later) {
        /* module entry */
        /// Availability: >= 2.5
        _symtable_entry *st_top;
    }
    /** dictionary of symbol table entries */
    PyObject* st_symbols;
    /** stack of namespace info */
    PyObject* st_stack;
    /** borrowed ref to MODULE in st_symbols */
    Borrowed!PyObject* st_global;
    version(Python_2_5_Or_Later) {
        /** number of blocks */
        /// Availability: >= 2.5
        int st_nblocks;
        /** name of current class or NULL */
        /// Availability: >= 2.5
        PyObject* st_private;
        /** temporary name counter */
        /// Availability: >= 2.5
        int st_tmpname;
    }else{
        /** number of scopes */
        /// Availability: 2.4
        int st_nscopes;
        /** number of errors */
        /// Availability: 2.4
        int st_errors;
        /** name of current class or NULL */
        /// Availability: 2.4
        char* st_private;
    }
    /** module's future features */
    PyFutureFeatures* st_future;
};

/// _
struct PySTEntryObject{
	mixin PyObject_HEAD;
        /** int: key in st_symbols) */
	PyObject* ste_id;
        /** dict: name to flags) */
	PyObject* ste_symbols;
        /** string: name of scope */
	PyObject* ste_name;
        /** list of variable names */
	PyObject* ste_varnames;
        /** list of child ids */
	PyObject* ste_children;
        version(Python_2_5_Or_Later) {
            /** module, class, or function */
            _Py_block_ty ste_type;
            /** false if namespace is optimized */
            /// Availability: >= 2.5
            int ste_unoptimized;
            /** true if block is nested */
            uint ste_nested ;
            /** true if block has free variables */
            /// Availability: >= 2.5
            uint ste_free ;
            /** true if a child block has free vars,
            including free refs to globals */
            uint ste_child_free ;
            /** true if namespace is a generator */
            uint ste_generator ;
            /** true if block has varargs */
            /// Availability: >= 2.5
            uint ste_varargs ;
            /** true if block has varkeywords */
            /// Availability: >= 2.5
            uint ste_varkeywords ;
            /** true if namespace uses return with
            an argument */
            /// Availability: >= 2.5
            uint ste_returns_value ;
            /** first line of block */
            int ste_lineno;

        }else{
            /** module, class, or function */
            int ste_type;
            /** first line of scope */
            int ste_lineno;
            /** true if namespace can't be optimized */
            /// Availability: 2.4
            int ste_optimized;
            /** true if scope is nested */
            int ste_nested;
            /** true if a child scope has free variables,
               including free refs to globals */
            int ste_child_free;
            /** true if namespace is a generator */
            int ste_generator;
        }
        /** lineno of last exec or import * */
	int ste_opt_lineno;
        /** temporary name counter */
	int ste_tmpname;
        /// _
	symtable* ste_table;
}

version(Python_2_5_Or_Later) {
    /// Availability: >= 2.5
    mixin(PyAPI_DATA!"PyTypeObject PySTEntry_Type");

    /// _
    int PySymtableEntry_Check()(PyObject* op) {
        return (Py_TYPE(op) is &PySTEntry_Type);
    }
    /// Availability: >= 2.5
    int PyST_GetScope(PySTEntryObject*, PyObject*);
    /// Availability: >= 2.5
    symtable* PySymtable_Build(
            mod_ty, const(char)*,
            PyFutureFeatures*);

    /// Availability: >= 2.5
    PySTEntryObject* PySymtable_Lookup(symtable*, void*);
    /// _
    void PySymtable_Free(symtable*);
}else{
    /// Availability: 2.4
    alias PySTEntryObject PySymtableEntryObject;
    /// Availability: 2.4
    mixin(PyAPI_DATA!"PyTypeObject PySymtableEntry_Type");

    /// _
    int PySymtableEntry_Check()(PyObject* op) {
        return (Py_TYPE(op) is &PySymtableEntry_Type);
    }

    /// Availability: 2.4
    PyObject* PySymtableEntry_New(
            symtable*,
            char*,
            int,
            int);
    /// Availability: 2.4
    symtable* PyNode_CompileSymtable(node*, const(char)*);
    /// _
    void PySymtable_Free(symtable*);
}


/* Flags for def-use information */

/** global stmt */
enum DEF_GLOBAL=1;
/** assignment in code block */
enum DEF_LOCAL=2;
/** formal parameter */
enum DEF_PARAM=2<<1;
/** name is used */
enum USE=2<<2;
version(Python_2_5_Or_Later) {
    /** name used but not defined in nested block */
    enum DEF_FREE=2<<3;
    /** free variable from class's method */
    enum DEF_FREE_CLASS=2<<4;
    /** assignment occurred via import */
    enum DEF_IMPORT=2<<5;
}else{
    /** parameter is star arg */
    enum DEF_STAR=2<<3;
    /** parameter is star-star arg */
    enum DEF_DOUBLESTAR=2<<4;
    /** name defined in tuple in parameters */
    enum DEF_INTUPLE=2<<5 ;
    /** name used but not defined in nested scope */
    enum DEF_FREE=2<<6;
    /** free variable is actually implicit global */
    enum DEF_FREE_GLOBAL=2<<7;
    /** free variable from class's method */
    enum DEF_FREE_CLASS=2<<8;
    /** assignment occurred via import */
    enum DEF_IMPORT=2<<9;
}

/// _
enum DEF_BOUND = (DEF_LOCAL | DEF_PARAM | DEF_IMPORT);

/// _
enum TYPE_FUNCTION =1;
/// _
enum TYPE_CLASS=2;
/// _
enum TYPE_MODULE=3;

/// _
enum LOCAL=1;
/// _
enum GLOBAL_EXPLICIT=2;
/// _
enum GLOBAL_IMPLICIT=3;
/// _
enum FREE=4;
/// _
enum CELL=5;

/// _
enum OPT_IMPORT_STAR=1;
/// _
enum OPT_EXEC=2;
/// _
enum OPT_BARE_EXEC=4;

/// _
enum GENERATOR=1;
/// _
enum GENERATOR_EXPRESSION=2;
