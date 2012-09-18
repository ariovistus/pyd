module deimos.python.symtable;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.compile;
import deimos.python.ast;
import deimos.python.node;

extern(C):

struct _symtable_entry;

version(Python_2_5_Or_Later) {
    enum _Py_block_ty{ FunctionBlock, ClassBlock, ModuleBlock }
}

struct symtable {
    version(Python_2_5_Or_Later) {
    }else{
	int st_pass;             /* pass == 1 or 2 */
    }
	const(char)*st_filename; /* name of file being compiled */
	_symtable_entry* st_cur; /* current symbol table entry */
        version(Python_2_5_Or_Later) {
            _symtable_entry *st_top; /* module entry */
        }
	PyObject* st_symbols;    /* dictionary of symbol table entries */
        PyObject* st_stack;      /* stack of namespace info */
	PyObject* st_global;     /* borrowed ref to MODULE in st_symbols */
        version(Python_2_5_Or_Later) {
            int st_nblocks;          /* number of blocks */
            PyObject* st_private;        /* name of current class or NULL */
            int st_tmpname;          /* temporary name counter */
        }else{
            int st_nscopes;          /* number of scopes */
            int st_errors;           /* number of errors */
            char* st_private;        /* name of current class or NULL */
        }
	PyFutureFeatures* st_future; /* module's future features */
};

struct PySTEntryObject{
	mixin PyObject_HEAD;
	PyObject* ste_id;        /* int: key in st_symbols) */
	PyObject* ste_symbols;   /* dict: name to flags) */
	PyObject* ste_name;      /* string: name of scope */
	PyObject* ste_varnames;  /* list of variable names */
	PyObject* ste_children;  /* list of child ids */
        version(Python_2_5_Or_Later) {
            _Py_block_ty ste_type;   /* module, class, or function */
            int ste_unoptimized;     /* false if namespace is optimized */
            uint ste_nested ;      /* true if block is nested */
            uint ste_free ;        /* true if block has free variables */
            uint ste_child_free ;  /* true if a child block has free vars,
                                             >                                        including free refs to globals */
            uint ste_generator ;   /* true if namespace is a generator */
            uint ste_varargs ;     /* true if block has varargs */
            uint ste_varkeywords ; /* true if block has varkeywords */
            uint ste_returns_value ;  /* true if namespace uses return with
                                                >                                           an argument */
            int ste_lineno;          /* first line of block */

        }else{
            int ste_type;            /* module, class, or function */
            int ste_lineno;          /* first line of scope */
            int ste_optimized;       /* true if namespace can't be optimized */
            int ste_nested;          /* true if scope is nested */
            int ste_child_free;      /* true if a child scope has free variables,
                                        including free refs to globals */
            int ste_generator;       /* true if namespace is a generator */
        }
	int ste_opt_lineno;      /* lineno of last exec or import * */
	int ste_tmpname;         /* temporary name counter */
	symtable* ste_table;
} 

version(Python_2_5_Or_Later) {
    __gshared PyTypeObject PySTEntry_Type;

    int PySymtableEntry_Check()(PyObject* op) {
        return (Py_TYPE(op) is &PySTEntry_Type);
    }
    int PyST_GetScope(PySTEntryObject*, PyObject*);
    symtable* PySymtable_Build(
            mod_ty, const(char)*, 
            PyFutureFeatures*);

    PySTEntryObject* PySymtable_Lookup(symtable*, void*);
    void PySymtable_Free(symtable*);
}else{
    alias PySTEntryObject PySymtableEntryObject;
    __gshared PyTypeObject PySymtableEntry_Type;

    int PySymtableEntry_Check()(PyObject* op) {
        return (Py_TYPE(op) is &PySymtableEntry_Type);
    }

    PyObject* PySymtableEntry_New(
            symtable*,
            char*, 
            int, 
            int);
    symtable* PyNode_CompileSymtable(node*, const(char)*);
    void PySymtable_Free(symtable*);
}





/* Flags for def-use information */

enum DEF_GLOBAL=1;          /* global stmt */
enum DEF_LOCAL=2;           /* assignment in code block */
enum DEF_PARAM=2<<1;        /* formal parameter */
enum USE=2<<2;              /* name is used */
version(Python_2_5_Or_Later) {
    enum DEF_FREE=2<<3;        /* name used but not defined in nested block */
    enum DEF_FREE_CLASS=2<<4;   /* free variable from class's method */
    enum DEF_IMPORT=2<<5;       /* assignment occurred via import */
}else{
    enum DEF_STAR=2<<3;         /* parameter is star arg */
    enum DEF_DOUBLESTAR=2<<4;   /* parameter is star-star arg */
    enum DEF_INTUPLE=2<<5 ;     /* name defined in tuple in parameters */
    enum DEF_FREE=2<<6;         /* name used but not defined in nested scope */
    enum DEF_FREE_GLOBAL=2<<7;  /* free variable is actually implicit global */
    enum DEF_FREE_CLASS=2<<8;   /* free variable from class's method */
    enum DEF_IMPORT=2<<9;       /* assignment occurred via import */
}

enum DEF_BOUND = (DEF_LOCAL | DEF_PARAM | DEF_IMPORT);

enum TYPE_FUNCTION =1;
enum TYPE_CLASS=2;
enum TYPE_MODULE=3;

enum LOCAL=1;
enum GLOBAL_EXPLICIT=2;
enum GLOBAL_IMPLICIT=3;
enum FREE=4;
enum CELL=5;

enum OPT_IMPORT_STAR=1;
enum OPT_EXEC=2;
enum OPT_BARE_EXEC=4;

enum GENERATOR=1;
enum GENERATOR_EXPRESSION=2;
