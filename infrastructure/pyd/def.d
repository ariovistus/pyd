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

import std.typetuple;
import std.traits;
import util.conv;
import util.typelist;
import pyd.func_wrap;

private PyMethodDef[] module_global_methods = [
    { null, null, 0, null }
];

private PyMethodDef[][string] module_methods;
version(Python_3_0_Or_Later) {
    private PyModuleDef*[string] pyd_moduledefs;
}
PyObject*[string] pyd_modules;

// this appears to be a python3-only thing that holds instantiators
// for wrapped classes and structs
private void delegate()[string][string] pyd_module_classes;

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

bool should_defer_class_wrap(string modulename, string classname) {
    version(Python_3_0_Or_Later) {
    return !(modulename in pyd_modules) && (modulename in pyd_module_classes)
        && !(classname in pyd_module_classes[modulename]);
    }else {
        return false;
    }
}
void defer_class_wrap(string modulename, string classname,
        void delegate() wrapper) {
    pyd_module_classes[modulename][classname] = wrapper;
}

/// Param of def
struct ModuleName(string _modulename) {
    enum modulename = _modulename;
}
template IsModuleName(T...) {
    import std.algorithm: startsWith;
    enum bool IsModuleName = T[0].stringof.startsWith("ModuleName!");
}

/// Param of def, Def, StaticDef
struct Docstring(string _doc) {
    enum doc = _doc;
}

template IsDocstring(T...) {
    import std.algorithm: startsWith;
    enum bool IsDocstring = T[0].stringof.startsWith("Docstring!");
}
/// Param of def, Def, StaticDef
struct PyName(string _name) {
    enum name = _name;
}
template IsPyName(T...) {
    import std.algorithm: startsWith;
    enum bool IsPyName = T[0].stringof.startsWith("PyName!");
}

/// Param of Property, Member
struct Mode(string _mode) {
    enum mode = _mode;
}
template IsMode(T...) {
    import std.algorithm: startsWith;
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

    alias Filter!(templateNot!IsModuleName,
          Filter!(templateNot!IsDocstring,
          Filter!(templateNot!IsPyName,
          Filter!(templateNot!IsMode,
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

    PyMethodDef empty;
    ready_module_methods(args.modulename);
    PyMethodDef[]* list = &module_methods[args.modulename];

    (*list)[$-1].ml_name = (args.pyname ~ "\0").dup.ptr;
    (*list)[$-1].ml_meth = cast(PyCFunction) &function_wrap!(fn,args.pyname).func;
    (*list)[$-1].ml_flags = METH_VARARGS | METH_KEYWORDS;
    (*list)[$-1].ml_doc = (args.docstring ~ "\0").dup.ptr;
    (*list) ~= empty;
}

template Typeof(alias fn0) {
    alias typeof(&fn0) Typeof;
}

template def_selector(alias fn, fn_t) {
    import std.string: format;

    alias alias_selector!(fn, fn_t) als;
    static if(als.VOverloads.length == 0 && als.Overloads.length != 0) {
        alias staticMap!(Typeof, als.Overloads) OverloadsT;
        static assert(0, format("%s not among %s",
                    fn_t.stringof,OverloadsT.stringof));
    }else static if(als.VOverloads.length > 1){
        static assert(0, format("%s: Cannot choose between %s", als.nom,
                    staticMap!(Typeof, als.VOverloads)));
    }else{
        alias als.VOverloads[0] FN;
    }
}

template IsEponymousTemplateFunction(alias fn) {
    // dmd issue 13372: its not a bug, its a feature!
    alias TypeTuple!(__traits(parent, fn))[0] Parent;
    enum IsEponymousTemplateFunction = is(typeof(Parent) == typeof(fn));
}

template alias_selector(alias fn, fn_t) {
    alias ParameterTypeTuple!fn_t ps;
    alias ReturnType!fn_t ret;
    alias TypeTuple!(__traits(parent, fn))[0] Parent;
    enum nom = __traits(identifier, fn);
    template IsDesired(alias f) {
        alias ParameterTypeTuple!f fps;
        alias ReturnType!f fret;
        enum bool IsDesired = is(ps == fps) && is(fret == ret);
    }
    static if(IsEponymousTemplateFunction!fn) {
        alias TypeTuple!(fn) Overloads;
    }else{
        alias TypeTuple!(__traits(getOverloads, Parent, nom)) Overloads;
    }
    alias Filter!(IsDesired, Overloads) VOverloads;
}

string pyd_module_name;

/// true after Py_Finalize has been called.
/// Playing with the Python API when this is true
/// is not advised.
__gshared Py_Finalize_called = false;

extern(C) void Py_Finalize_hook() {
    import thread = pyd.thread;
    Py_Finalize_called = true;
    thread.detachAll();
}

version(PydPythonExtension)
{
    /// For embedding python
    void py_init()()
    {
        static assert(false, "py_init should only be called when embedding python");
    }
}
else
{
    /// For embedding python
    void py_init() {
        doActions(PyInitOrdering.Before);
        Py_Initialize();
        py_init_called = true;
        doActions(PyInitOrdering.After);
        version(Python_3_0_Or_Later) {
            // stinking python 3 lazy initializes modules.
            import pyd.embedded;
            foreach(modulename, _; pyd_module_classes) {
                py_import(modulename);
            }
        }
    }
}

/// For embedding python, should you wish to restart the interpreter.
void py_finish() {
    Py_Finalize();
    Py_Finalize_hook();
    py_init_called = false;
}

/**
 * Module initialization function. Should be called after the last call to def.
 * For extending python.
 */
PyObject* module_init(string docstring="") {
    Py_AtExit(&Py_Finalize_hook);
    string name = pyd_module_name;
    ready_module_methods("");
    version(Python_3_0_Or_Later) {
        PyModuleDef* modl = pyd_moduledefs[""] = new PyModuleDef;
        (cast(PyObject*) modl).ob_refcnt = 1;
        modl.m_name = zcc(name);
        modl.m_doc = zcc(docstring);
        modl.m_size = -1;
        modl.m_methods = module_methods[""].ptr;
        pyd_module_classes[""] = (void delegate()[string]).init;

        Py3_ModuleInit!"".func();
    }else {
        pyd_modules[""] = Py_INCREF(Py_InitModule3((name ~ "\0"),
                    module_methods[""].ptr, (docstring ~ "\0")));
    }
    doActions(PyInitOrdering.Before);
    doActions(PyInitOrdering.After);
    py_init_called = true;
    return pyd_modules[""];
}

/**
Module initialization function. Should be called after the last call to def.

This may not be supportable in Python 3 extensions.

Params
Options = Optional parameters. Takes Docstring!(docstring), and ModuleName!(modulename)
modulename = name of module
docstring = docstring of module
 */
void add_module(Options...)() {
    alias Args!("","", "", "",Options) args;
    enum modulename = args.modulename;
    enum docstring = args.docstring;
    ready_module_methods(modulename);
    version(Python_3_0_Or_Later) {
        assert(!py_init_called);
        version(PydPythonExtension) {
            static assert(false, "add_module is not properly supported in python3 at this time");
        }
        PyModuleDef* modl = new PyModuleDef;
        Py_SET_REFCNT(modl, 1);
        modl.m_name = zcc(modulename);
        modl.m_doc = zcc(docstring);
        modl.m_size = -1;
        modl.m_methods = module_methods[modulename].ptr;
        pyd_moduledefs[modulename] = modl;
        pyd_module_classes[modulename] = (void delegate()[string]).init;

        PyImport_AppendInittab(modulename.ptr, &Py3_ModuleInit!modulename.func);
    }else{
        // schizophrenic arrangements, these
        version(PydPythonExtension) {
        }else{
            assert(py_init_called);
        }
        pyd_modules[modulename] = Py_INCREF(Py_InitModule3((modulename ~ "\0"),
                    module_methods[modulename].ptr, (docstring ~ "\0")));
    }
}

template Py3_ModuleInit(string modulename) {
    extern(C) PyObject* func() {
        pyd_modules[modulename] = PyModule_Create(pyd_moduledefs[modulename]);
        foreach(n,action; pyd_module_classes[modulename]) {
            action();
        }
        return pyd_modules[modulename];
    }
}

bool py_init_called = false;
void delegate()[] before_py_init_deferred_actions;
void delegate()[] after_py_init_deferred_actions;

void doActions(PyInitOrdering which) {
    auto actions = before_py_init_deferred_actions;
    if (which == PyInitOrdering.Before) {
    }else if(which == PyInitOrdering.After) {
        actions = after_py_init_deferred_actions;
    }else assert(false);
    foreach(action; actions) {
        action();
    }
}

///
enum PyInitOrdering{
    /// call will be made before Py_Initialize.
    Before,
    /// call will be made after Py_Initialize.
    After,
}

/// call will be made at the appropriate time for initializing
/// modules.  (for python 2, it should be after Py_Initialize,
/// for python 3, before).
version(Python_3_0_Or_Later) {
    enum PyInitOrdering ModuleInit = PyInitOrdering.Before;
}else{
    enum PyInitOrdering ModuleInit = PyInitOrdering.After;
}

/**
  Use this to wrap calls to add_module and the like.

  py_init will ensure they are called at the appropriate time
  */
void on_py_init(void delegate() dg,
        PyInitOrdering ord = ModuleInit) {
    import std.exception: enforce;

    with(PyInitOrdering) switch(ord) {
        case Before:
            if(py_init_called) {
                enforce(0, "py_init has already been called");
            }
            before_py_init_deferred_actions ~= dg;
            break;
        case After:
            if(py_init_called) {
                dg();
            }
            after_py_init_deferred_actions ~= dg;
            break;
        default:
            assert(0);
    }
}

