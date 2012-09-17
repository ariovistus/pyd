module python2.compile;

import python2.code;
import python2.node;
import python2.pythonrun;

extern(C):
// Python-header-file: Include/compile.h:

PyCodeObject* PyNode_Compile(node*, const(char)*);

struct PyFutureFeatures {
    version(Python_2_5_Or_Later){
        int ff_features;
        int ff_lineno;
    }else{
        int ff_found_docstring;
        int ff_last_linno;
        int ff_features;
    }
}

version(Python_2_5_Or_Later){
}else{
    PyFutureFeatures *PyNode_Future(node*, const(char)*);
    PyCodeObject *PyNode_CompileFlags(node*, const(char)*, PyCompilerFlags*);
}

enum FUTURE_NESTED_SCOPES = "nested_scopes";
enum FUTURE_GENERATORS = "generators";
enum FUTURE_DIVISION = "division";
version(Python_2_5_Or_Later){
    enum FUTURE_ABSOLUTE_IMPORT = "absolute_import";
    enum FUTURE_WITH_STATEMENT = "with_statement";
    version(Python_2_6_Or_Later){
        enum FUTURE_PRINT_FUNCTION = "print_function";
        enum FUTURE_UNICODE_LITERALS = "unicode_literals";
    }
    version(Python_3_0_Or_Later) {
        enum FUTURE_BARRY_AS_BDFL = "barry_as_FLUFL";
    }

    struct _mod; /* Declare the existence of this type */
    version(Python_3_0_Or_Later) {
        PyCodeObject* PyAST_Compile()(_mod* mod, const(char)* s, 
                PyCompilerFlags* f, PyArena* ar) {
            return PyAST_CompileEx(mod, s, f, -1, ar)
        }
        PyCodeObject* PyAST_CompileEx(
                _mod* mod,
                const(char)* filename,       /* decoded from the filesystem encoding */
                PyCompilerFlags* flags,
                int optimize,
                PyArena* arena);
    }else {
        PyCodeObject* PyAST_Compile(
                _mod*, const(char)*, PyCompilerFlags*, PyArena*);
    }
    PyFutureFeatures* PyFuture_FromAST(_mod*, const(char)*);
}
