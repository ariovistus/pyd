/**
  Mirror _compile.h
  */
module deimos.python.compile;

import deimos.python.code;
import deimos.python.node;
import deimos.python.pythonrun;
import deimos.python.pyarena;

extern(C):
// Python-header-file: Include/compile.h:

/// _
PyCodeObject* PyNode_Compile(node*, const(char)*);

/// _
struct PyFutureFeatures {
    version(Python_2_5_Or_Later){
        /** flags set by future statements */
        /// Availability: >= 2.5
        int ff_features;
        /** line number of last future statement */
        /// Availability: >= 2.5
        int ff_lineno;
    }else{
        /// Availability: <= 2.4
        int ff_found_docstring;
        /// Availability: <= 2.4
        int ff_last_linno;
        /// Availability: <= 2.4
        int ff_features;
    }
}

version(Python_2_5_Or_Later){
}else{
    /// Availability: <= 2.4
    PyFutureFeatures *PyNode_Future(node*, const(char)*);
    /// Availability: <= 2.4
    PyCodeObject *PyNode_CompileFlags(node*, const(char)*, PyCompilerFlags*);
}

/// _
enum FUTURE_NESTED_SCOPES = "nested_scopes";
/// _
enum FUTURE_GENERATORS = "generators";
/// _
enum FUTURE_DIVISION = "division";
version(Python_2_5_Or_Later){
    /// Availability: >= 2.5
    enum FUTURE_ABSOLUTE_IMPORT = "absolute_import";
    /// Availability: >= 2.5
    enum FUTURE_WITH_STATEMENT = "with_statement";
    version(Python_2_6_Or_Later){
        /// Availability: >= 2.6
        enum FUTURE_PRINT_FUNCTION = "print_function";
        /// Availability: >= 2.6
        enum FUTURE_UNICODE_LITERALS = "unicode_literals";
    }
    version(Python_3_0_Or_Later) {
        /// Availability: >= 3.2
        enum FUTURE_BARRY_AS_BDFL = "barry_as_FLUFL";
    }

    /// _
    struct _mod; /* Declare the existence of this type */
    version(Python_3_2_Or_Later) {
        /// Availability: >= 3.2
        PyCodeObject* PyAST_Compile()(_mod* mod, const(char)* s, 
                PyCompilerFlags* f, PyArena* ar) {
            return PyAST_CompileEx(mod, s, f, -1, ar);
        }
        /**
Params:
filename = decoded from the filesystem encoding 
*/
        /// Availability: >= 3.2
        PyCodeObject* PyAST_CompileEx(
                _mod* mod,
                const(char)* filename,       
                PyCompilerFlags* flags,
                int optimize,
                PyArena* arena);
    }else {
        /// Availability: 2.*
        PyCodeObject* PyAST_Compile(
                _mod*, const(char)*, PyCompilerFlags*, PyArena*);
    }
    /// Availability: >= 2.5
    PyFutureFeatures* PyFuture_FromAST(_mod*, const(char)*);
}
