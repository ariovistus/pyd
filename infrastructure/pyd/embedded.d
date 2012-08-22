/*
Copyright (c) 2012 Ellery Newcomer

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
module pyd.embedded;

/+
 + Things we want to do:
 +  * run python code in D (easily) [check]
 +  * run D code in python [check]
 +  * declare python functions and use them in D [check]
 +  * access and manipulate python globals in D [check]
 +  * wrap D classes/structs and use them in python or D [check]
 +  * use python class instances in D [check]
 +  * wrap D ranges and iterators or whatever and iterate through them in python [why?]
 +  * wrap python iterators as D input ranges [why?]
 +  * do things with inheritance [why??!??]
 +/  

import python;
import pyd.pyd;
import std.algorithm: findSplit;
import std.string: strip;

shared static this() {
    Py_Initialize();
}

/++
 + Fetch a python module object.
 +/
PydObject py_import(string name) {
    return new PydObject(PyImport_ImportModule(zcc(name)));
}

/++
 + Take a python function and wrap it so we can call it from D!
 +/
R PyDef( string python, string modl, R, Args...)
    (Args args, string file = __FILE__, size_t line = __LINE__) {

    //Note that type is really the only thing that need be static here, but hey.
    enum afterdef = findSplit(python, "def")[2];
    enum ereparen = findSplit(afterdef, "(")[0];
    enum name = strip(ereparen) ~ "\0";
    static PydObject func; 
    static PythonException exc;
    static string errmsg;
    static bool once = true;
    if(once) {
        once = false;
        auto m = py_import(modl);
        auto locals = m.getdict();
        auto locals_ptr = OwnPyRef(m.getdict().ptr);
        if("__builtins__" !in locals) {
            auto builtins = new PydObject(PyEval_GetBuiltins());
            locals["__builtins__"] = builtins;
        }
        auto pres = PyRun_String(
                    zcc(python), 
                    Py_file_input, locals_ptr, locals_ptr);
        scope(exit) Py_DECREF(locals_ptr);
        if(pres) {
            auto res = new PydObject(pres);
            func = m.getattr(name);
        }else{
            try{
                handle_exception();
            }catch(PythonException e) {
                exc = e;
            }
        }
    }
    if(!func) {
        throw exc;
    }
    return func(args).toDItem!R();
}

/++
 + Evaluate a python expression once and return the result.
 +/
T PyEval(T = PydObject)(string python, string modl, string file = __FILE__, size_t line = __LINE__) {
    auto m = py_import(modl);
    auto locals = m.getdict();
    auto locals_ptr = OwnPyRef(m.getdict().ptr);
    if("__builtins__" !in locals) {
        auto builtins = new PydObject(PyEval_GetBuiltins());
        locals["__builtins__"] = builtins;
    }
    auto pres = PyRun_String(
            zcc(python), 
            Py_eval_input, locals_ptr, locals_ptr);
    scope(exit) Py_DECREF(locals_ptr);
    if(pres) {
        auto res = new PydObject(pres);
        return res.toDItem!T();
    }else{
        handle_exception(file,line);
        assert(0);
    }
}

/++
 + Evaluate one or more python statements once.
 +/
void PyStmts(string python, string modl,string file = __FILE__, size_t line = __LINE__) {
    auto m = py_import(modl);
    auto locals = m.getdict();
    auto locals_ptr = OwnPyRef(locals.ptr);
    if("__builtins__" !in locals) {
        auto builtins = new PydObject(PyEval_GetBuiltins());
        locals["__builtins__"] = builtins;
    }
    auto pres = PyRun_String(
            zcc(python), 
            Py_file_input, locals_ptr, locals_ptr);
    scope(exit) Py_DECREF(locals_ptr);
    if(pres) {
        Py_DECREF(pres);
    }else{
        handle_exception(file,line);
    }
}
/++
 + PyErr_Print() prints error messages to stderr,
 + but it is nicer in a string so we can stuff it in an Exception.
 + An instance of this class can be assigned to sys.stderr
 + to do just that. (we could use StringIO, but this is a nice demonstration
 + of Things We Can Do with Embedded Python):
-------
Py_Initialize();
add_module("pyd");
ErrInterceptor.wrap_class("pyd");
ErrInterceptor.replaceStderr();
...
PyEval("1 + 'a'");
-------
 +/
class ErrInterceptor {

    PydObject old_stderr;

    this(PydObject obj) {
        old_stderr = obj;
    }
    string _msg;
    void write(string s) {
        import std.stdio;
        writeln("stderr: ",s);
        _msg ~= s;
        old_stderr.write(s);
    }
    void clear() {
        _msg = "";
    }
    string msg(){
        return _msg;
    }

    static void wrap_class(string modl) {
        .wrap_class!(ErrInterceptor, 
            Init!(void function(PydObject)),
            Def!(ErrInterceptor.write),
            Def!(ErrInterceptor.clear),
            Def!(ErrInterceptor.msg))(
            "A simple stream -> string utility implemented in D", // docstring
            modl); // module name
    }
    static void replaceStderr() {
        auto sys = py_import("sys");
        sys.stderr = new ErrInterceptor(sys.stderr);
    }
    static string interceptStderr() {
        auto z = PyErr_Occurred();
        if(!z) {
            import std.stdio;
            writeln("no error occurred!");
            return "";
        }
        string errmsg;
        auto stderr = py_import("sys").stderr;
        if(!stderr.hasattr("msg")) {
            // whoops, stderr isn't ErrInterceptor
            return z.toString();
        }
        PyErr_Print();
        auto msg = stderr.method("msg");
        if(msg != None) {
            errmsg = msg.toDItem!string();
        }
        PyErr_Clear();
        stderr.method("clear");
        return errmsg;
    }
}
