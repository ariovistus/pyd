/*
Copyright (c) 2006 Kirk McDonald

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

/**
  Contains utilities for wrapping D functions.
  */
module pyd.def;

import deimos.python.Python;

import std.algorithm: startsWith;
import std.metastrings;
import std.typetuple;
import std.traits;
import util.typelist;
import pyd.func_wrap;

private PyMethodDef module_global_methods[] = [
    { null, null, 0, null }
];

private PyMethodDef[][string] module_methods;
private PyObject*[string] pyd_modules;

private void ready_module_methods(string modulename) {
    PyMethodDef empty;
    if (!(modulename in module_methods)) {
        module_methods[modulename] = (PyMethodDef[]).init;
        module_methods[modulename] ~= empty;
    }
}

PyObject* Pyd_Module_p(string modulename="") {
    PyObject** m = modulename in pyd_modules;
    if (m is null) return null;
    else return *m;
}

/// Param of def
struct ModuleName(string _modulename) {
    enum modulename = _modulename;
}
template IsModuleName(T...) {
    enum bool IsModuleName = T[0].stringof.startsWith("ModuleName!");
}

/// Param of def, Def, StaticDef
struct Docstring(string _doc) {
    enum doc = _doc;
}

template IsDocstring(T...) {
    enum bool IsDocstring = T[0].stringof.startsWith("Docstring!");
}
/// Param of def, Def, StaticDef
struct PyName(string _name) {
    enum name = _name;
}
template IsPyName(T...) {
    enum bool IsPyName = T[0].stringof.startsWith("PyName!");
}

/// Param of Property, Member
struct Mode(string _mode) {
    enum mode = _mode;
}
template IsMode(T...) {
    enum bool IsMode = T[0].stringof.startsWith("Mode!");
}

struct Args(string default_modulename,
            string default_docstring,
            string default_pyname,
            string default_mode,
            Params...) {
    alias Filter!(IsDocstring, Params) Docstrings;
    static if(Docstrings.length) {
        enum docstring = Docstrings[0].doc;
    }else{
        enum docstring = default_docstring;
    }
    alias Filter!(IsPyName, Params) PyNames;
    static if(PyNames.length) {
        enum pyname = PyNames[0].name;
    }else{
        enum pyname = default_pyname;
    }
    alias Filter!(IsMode, Params) Modes;
    static if(Modes.length) {
        enum mode = Modes[0].mode;
    }else{
        enum mode = default_mode;
    }
    alias Filter!(IsModuleName, Params) ModuleNames;
    static if(ModuleNames.length) {
        enum modulename = ModuleNames[0].modulename;
    }else{
        enum modulename = default_modulename;
    }

    alias Filter!(Not!IsModuleName, 
          Filter!(Not!IsDocstring, 
          Filter!(Not!IsPyName,
          Filter!(Not!IsMode,
              Params)))) rem;
    template IsString(T...) {
        enum bool IsString = is(typeof(T[0]) == string);
    }
    static if(Filter!(IsString, rem).length) {
        static assert(false, "string parameters must be wrapped with Docstring, Mode, etc");
    }
}

/**
Wraps a D function, making it callable from Python.

Supports default arguments, typesafe variadic arguments, and python's 
keyword arguments.
 
Params:

fn   = The function to wrap.
Options = Optional parameters. Takes Docstring!(docstring), PyName!(pyname), ModuleName!(modulename), and fn_t
modulename = The name of the python module in which the wrapped function 
            resides.
pyname = The name of the function as it will appear in Python.
fn_t = The function type of the function to wrap. This must be
            specified if more than one function shares the same name,
            otherwise the first one defined lexically will be used.
docstring = The function's docstring. 

Examples:
---
import pyd.pyd;
string foo(int i) {
    if (i > 10) {
        return "It's greater than 10!";
    } else {
        return "It's less than 10!";
    }
}
extern (C)
export void inittestdll() {
    def!(foo, ModuleName!"testdll");
    add_module("testdll");
}
---
 And in Python:
$(D_CODE >>> import testdll
>>> print testdll.foo(20)
It's greater than 10!)
 */


void def(alias _fn, Options...)() {
    alias Args!("","", __traits(identifier,_fn), "",Options) args;
    static if(args.rem.length) {
        alias args.rem[0] fn_t;
    }else {
        alias typeof(&_fn) fn_t;
    }
    alias def_selector!(_fn, fn_t).FN fn;
    pragma(msg, "def: " ~ args.pyname);
    PyMethodDef empty;
    ready_module_methods(args.modulename);
    PyMethodDef[]* list = &module_methods[args.modulename];

    (*list)[$-1].ml_name = (args.pyname ~ "\0").dup.ptr;
    (*list)[$-1].ml_meth = cast(PyCFunction) &function_wrap!fn.func;
    (*list)[$-1].ml_flags = METH_VARARGS | METH_KEYWORDS;
    (*list)[$-1].ml_doc = (args.docstring ~ "\0").dup.ptr;
    (*list) ~= empty;
}

template Typeof(alias fn0) {
    alias typeof(&fn0) Typeof;
}

template def_selector(alias fn, fn_t) {
    alias alias_selector!(fn, fn_t) als;
    static if(als.VOverloads.length == 0 && als.Overloads.length != 0) {
        alias staticMap!(Typeof, als.Overloads) OverloadsT;
        static assert(0, Format!("%s not among %s", 
                    fn_t.stringof,OverloadsT.stringof));
    }else static if(als.VOverloads.length > 1){
        static assert(0, Format!("%s: Cannot choose between %s", als.nom, 
                    staticMap!(Typeof, als.VOverloads)));
    }else{
        alias als.VOverloads[0] FN;
    }
}

template alias_selector(alias fn, fn_t) {
    alias ParameterTypeTuple!fn_t ps; 
    alias ReturnType!fn_t ret;
    alias TypeTuple!(__traits(parent, fn))[0] Parent;
    enum nom = __traits(identifier, fn);
    alias TypeTuple!(__traits(getOverloads, Parent, nom)) Overloads;
    template IsDesired(alias f) {
        alias ParameterTypeTuple!f fps;
        alias ReturnType!f fret;
        enum bool IsDesired = is(ps == fps) && is(fret == ret);
    }
    alias Filter!(IsDesired, Overloads) VOverloads;
}

string pyd_module_name;

/**
 * Module initialization function. Should be called after the last call to def.
 * For extending python.
 */
PyObject* module_init(string docstring="") {
    //_loadPythonSupport();
    string name = pyd_module_name;
    ready_module_methods("");
    pyd_modules[""] = cast(PyObject*) Py_InitModule3(name ~ "\0", module_methods[""].ptr, docstring ~ "\0");
    foreach(action; on_module_init_deferred_actions) {
        action();
    }
    module_init_called = true;
    return pyd_modules[""];
}

/// For embedding python
void py_init() {
    Py_Initialize();
    foreach(action; on_module_init_deferred_actions) {
        action();
    }
    module_init_called = true;
}

/**
 * Module initialization function. Should be called after the last call to def.
 */
PyObject* add_module(string modulename, string docstring="") {
    ready_module_methods(modulename);
    pyd_modules[modulename] = cast(PyObject*) Py_InitModule3(modulename ~ "\0", module_methods[modulename].ptr, docstring ~ "\0");
    return pyd_modules[modulename];
}

bool module_init_called = false;
void delegate()[] on_module_init_deferred_actions;
void on_module_init(void delegate() dg) {
    if(module_init_called) {
        dg();
    }else {
        on_module_init_deferred_actions ~= dg;
    }
}

