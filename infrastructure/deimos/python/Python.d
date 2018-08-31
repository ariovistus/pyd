module deimos.python.Python;

/// start symbol for evaluating a single statement.
enum int Py_single_input = 256;
/// start symbol for evaluating multiple statements.
enum int Py_file_input = 257;
/// start symbol for evaluating a single expression.
enum int Py_eval_input = 258;

version(Python_2_4_Or_Later) {
    public import deimos.python.abstract_;
    public import deimos.python.ast;
    public import deimos.python.boolobject;
    public import deimos.python.bufferobject;
    public import deimos.python.bytearrayobject;
    public import deimos.python.bytesobject;
    public import deimos.python.cellobject;
    public import deimos.python.ceval;
    public import deimos.python.classobject;
    public import deimos.python.cobject;
    public import deimos.python.code;
    public import deimos.python.codecs;
    public import deimos.python.compile;
    public import deimos.python.complexobject;
    public import deimos.python.context;
    public import deimos.python.cStringIO;
    public import deimos.python.datetime;
    public import deimos.python.descrobject;
    public import deimos.python.dictobject;
    public import deimos.python.enumobject;
    public import deimos.python.errcode;
    public import deimos.python.eval;
    public import deimos.python.fileobject;
    public import deimos.python.floatobject;
    public import deimos.python.frameobject;
    public import deimos.python.funcobject;
    public import deimos.python.genobject;
    public import deimos.python.grammar;
    public import deimos.python.import_;
    public import deimos.python.intobject;
    public import deimos.python.intrcheck;
    public import deimos.python.iterobject;
    public import deimos.python.listobject;
    public import deimos.python.longintrepr;
    public import deimos.python.longobject;
    public import deimos.python.marshal;
    public import deimos.python.memoryobject;
    public import deimos.python.methodobject;
    public import deimos.python.modsupport;
    public import deimos.python.moduleobject;
    public import deimos.python.node;
    public import deimos.python.object;
    public import deimos.python.objimpl;
    public import deimos.python.odictobject;
    public import deimos.python.osmodule;
    public import deimos.python.parsetok;
    public import deimos.python.pgenheaders;
    public import deimos.python.pyarena;
    public import deimos.python.pyatomic;
    public import deimos.python.pycapsule;
    public import deimos.python.pydebug;
    public import deimos.python.pyerrors;
    public import deimos.python.pymem;
    public import deimos.python.pyport;
    public import deimos.python.pystate;
    public import deimos.python.pystrcmp;
    public import deimos.python.pystrtod;
    public import deimos.python.pythonrun;
    public import deimos.python.pythread;
    public import deimos.python.rangeobject;
    public import deimos.python.setobject;
    public import deimos.python.sliceobject;
    public import deimos.python.stringobject;
    public import deimos.python.structmember;
    public import deimos.python.structseq;
    public import deimos.python.symtable;
    public import deimos.python.sysmodule;
    public import deimos.python.timefuncs;
    public import deimos.python.traceback;
    public import deimos.python.tupleobject;
    public import deimos.python.unicodeobject;
    public import deimos.python.warnings;
    public import deimos.python.weakrefobject;
}else{
    static assert(0, "You are missing python version flags");

    //dmd may ignore the assert
    pragma(msg, "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    pragma(msg, "You are missing python version flags");
    pragma(msg, "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
}
