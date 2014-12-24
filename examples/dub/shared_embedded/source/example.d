import pyd.pyd, pyd.embedded;
import deimos.python.Python;
import std.stdio;

shared static this(){
    py_init();
    initSctipts();
}
InterpContext pyLogic;

void initSctipts(){
    pyLogic = new InterpContext();
    pyLogic.py_stmts("import sys");
    pyLogic.py_stmts("import os");
    pyLogic.py_stmts("sys.path.append(os.getcwd()+'/scripts/')");
    pyLogic.py_stmts("import logic");
}
shared static ~this(){
    py_finish();
}
