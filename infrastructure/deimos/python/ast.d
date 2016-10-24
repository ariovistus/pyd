/**
  Mirror _ast.h
  */
module deimos.python.ast;

import deimos.python.compile;
import deimos.python.pyarena;
import deimos.python.node;
import deimos.python.pythonrun;

extern(C): version(Python_2_5_Or_Later) {
// Python-header-file: Include/ast.h:

/// Availability: >= 2.5
alias _mod* mod_ty;

/// Availability: >= 2.5
mod_ty* PyAST_FromNode(
        const(node)* n,
        PyCompilerFlags* flags,
        const(char)* filename,
        PyArena* arena);
}
