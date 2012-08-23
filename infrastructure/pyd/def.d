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
module pyd.def;

import python;

import std.metastrings;
import std.typetuple;
import std.traits;
import util.typelist;
import pyd.func_wrap;
import pyd.lib_abstract :
    symbolnameof,
    minArgs
;

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

/**
 * Wraps a D function, making it callable from Python.
 *
 * Params:
 *      name = The name of the function as it will appear in Python.
 *      fn   = The function to wrap.
 *      MIN_ARGS = The minimum number of arguments this function can accept.
 *                 For use with functions with default arguments. Defaults to
 *                 the maximum number of arguments this function supports.
 *      fn_t = The function type of the function to wrap. This must be
 *             specified if more than one function shares the same name,
 *             otherwise the first one defined lexically will be used.
 *
 * Examples:
 *$(D_CODE import pyd.pyd;
 *string foo(int i) {
 *    if (i > 10) {
 *        return "It's greater than 10!";
 *    } else {
 *        return "It's less than 10!";
 *    }
 *}
 *extern (C)
 *export void inittestdll() {
 *    _def!("foo", foo);
 *    module_init("testdll");
 *})
 * And in Python:
 *$(D_CODE >>> import testdll
 *>>> print testdll.foo(20)
 *It's greater than 10!)
 */
void def(alias fn, string name = symbolnameof!(fn), fn_t=typeof(&fn)) 
    (string docstring="") {
    def!("", fn, name, fn_t)(docstring);
}
void def(string modulename, alias fn, fn_t=typeof(&fn)) 
    (string docstring="") {
    def!(modulename, fn, __traits(identifier,fn), fn_t)(docstring);
}

void def(alias fn, fn_t=typeof(&fn)) (string docstring="") {
    def!("", fn, symbolnameof!(fn), fn_t)(docstring);
}

void def(string modulename, alias _fn, string name = symbolnameof!(_fn), 
        fn_t=typeof(&_fn)) 
    (string docstring) {
    alias def_selector!(_fn, fn_t).FN fn;
    pragma(msg, "def: " ~ name);
    PyMethodDef empty;
    ready_module_methods(modulename);
    PyMethodDef[]* list = &module_methods[modulename];

    (*list)[$-1].ml_name = (name ~ "\0").dup.ptr;
    (*list)[$-1].ml_meth = cast(PyCFunction) &function_wrap!fn.func;
    (*list)[$-1].ml_flags = METH_VARARGS | METH_KEYWORDS;
    (*list)[$-1].ml_doc = (docstring ~ "\0").dup.ptr;
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
        alias ReturnType!fn fret;
        enum bool IsDesired = is(ps == fps) && is(fret == ret);
    }
    alias Filter!(IsDesired, Overloads) VOverloads;
}

string pyd_module_name;

/**
 * Module initialization function. Should be called after the last call to def.
 */
PyObject* module_init(string docstring="") {
    //_loadPythonSupport();
    string name = pyd_module_name;
    ready_module_methods("");
    pyd_modules[""] = cast(PyObject*) Py_InitModule3(name ~ "\0", module_methods[""].ptr, docstring ~ "\0");
    return pyd_modules[""];
}

/**
 * Module initialization function. Should be called after the last call to def.
 */
PyObject* add_module(string name, string docstring="") {
    ready_module_methods(name);
    pyd_modules[name] = cast(PyObject*) Py_InitModule3(name ~ "\0", module_methods[name].ptr, docstring ~ "\0");
    return pyd_modules[name];
}

