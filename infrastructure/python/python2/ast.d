module python2.ast;

import python2.compile;
import python2.pyarena;

extern(C): version(Python_2_5_Or_Later):

alias _mod* mod_ty;

version(Python_2_5_Or_Later){
    mod_ty* PyAST_FromNode(const(node)*, PyCompilerFlags*, const(char)*, 
            PyArena*);
}
