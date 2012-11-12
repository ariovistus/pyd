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
  Mostly internal utilities.
  */
module pyd.func_wrap;

import deimos.python.Python;
import std.algorithm: max;
import std.metastrings;
import std.exception: enforce;
import std.range;
import std.conv;
import util.typelist;

import pyd.class_wrap;
import pyd.exception;
import pyd.make_object;

import std.traits;

template hasFunctionAttrs(T) {
    static if(isDelegate!T || isFunctionPointer!T) {
        enum bool hasFunctionAttrs = functionAttributes!T != 
            FunctionAttribute.none;
    }else{
        enum bool hasFunctionAttrs = false;
    }
}

// Builds a callable Python object from a delegate or function pointer.
void PydWrappedFunc_Ready(S)() {
    static if(hasFunctionAttrs!S) {
        alias SetFunctionAttributes!(S, 
                functionLinkage!S, 
                FunctionAttribute.none) T;
    }else{
        alias S T;
    }
    alias wrapped_class_type!(T) type;
    alias wrapped_class_object!(T) obj;
    if (!is_wrapped!(T)) {
        init_PyTypeObject!T(type);
        Py_SET_TYPE(&type, &PyType_Type);
        type.tp_basicsize = obj.sizeof;
        type.tp_name = "PydFunc".ptr;
        type.tp_flags = Py_TPFLAGS_DEFAULT;

        type.tp_call = &wrapped_func_call!(T).call;

        PyType_Ready(&type);
        is_wrapped!T = true;
    }
}

void setWrongArgsError(Py_ssize_t gotArgs, size_t minArgs, size_t maxArgs, string funcName="") {

    string argStr(size_t args) {
        string temp = to!string(args) ~ " argument";
        if (args > 1) {
            temp ~= "s";
        }
        return temp;
    }
    string str = (funcName == ""?"function":funcName~"()") ~ "takes";

    if (minArgs == maxArgs) {
        if (minArgs == 0) {
            str ~= "no arguments";
        } else {
            str ~= "exactly " ~ argStr(minArgs);
        }
    }
    else if (gotArgs < minArgs) {
        str ~= "at least " ~ argStr(minArgs);
    } else {
        str ~= "at most " ~ argStr(maxArgs);
    }
    str ~= " (" ~ to!string(gotArgs) ~ " given)";

    PyErr_SetString(PyExc_TypeError, (str ~ "\0").dup.ptr);
}

// Calls callable alias fn with PyTuple args.
// kwargs may be null, args may not
ReturnType!fn applyPyTupleToAlias(alias fn, string fname)(PyObject* args, PyObject* kwargs) {
    alias ParameterTypeTuple!fn T;
    enum size_t MIN_ARGS = minArgs!fn;
    alias maxArgs!fn MaxArgs;
    alias ReturnType!fn RT;
    bool argsoverwrote = false;

    Py_ssize_t argCount = 0;
    // This can make it more convenient to call this with 0 args.
    if(kwargs !is null && PyObject_Length(kwargs) > 0) {
        args = arrangeNamedArgs!(fn,fname)(args, kwargs);
        Py_ssize_t newlen = PyObject_Length(args);
        argsoverwrote = true;
    }
    scope(exit) if(argsoverwrote) Py_DECREF(args);
    if (args !is null) {
        argCount += PyObject_Length(args);
    }

    // Sanity check!
    if (!supportsNArgs!(fn)(argCount)) {
        setWrongArgsError(cast(int) argCount, MIN_ARGS, 
                (MaxArgs.hasMax ? MaxArgs.max:-1));
        handle_exception();
    }

    static if (MaxArgs.vstyle == Variadic.no && MIN_ARGS == 0) {
        if (argCount == 0) {
            return fn();
        }
    }
    MaxArgs.ps t;
    foreach(i, arg; t) {
        enum size_t argNum = i+1;
        static if(MaxArgs.vstyle == Variadic.no) {
            alias ParameterDefaultValueTuple!fn Defaults;
            if (i < argCount) {
                auto bpobj =  PyTuple_GetItem(args, i);
                if(bpobj) {
                    auto pobj = Py_XINCREF(bpobj);
                    t[i] = python_to_d!(typeof(arg))(pobj);
                    Py_DECREF(pobj);
                }else{
                    static if(!is(Defaults[i] == void)) {
                        t[i] = Defaults[i];
                    }else{
                        // should never happen
                        enforce(0, "python non-keyword arg is NULL!");
                    }
                }
            }
            static if (argNum >= MIN_ARGS && 
                    (!MaxArgs.hasMax || argNum <= MaxArgs.max)) {
                if (argNum == argCount) {
                    return fn(t[0 .. argNum]);
                    break;
                }
            }
        }else static if(MaxArgs.vstyle == Variadic.typesafe) {
            static if (argNum < t.length) {
                auto pobj = Py_XINCREF(PyTuple_GetItem(args, i));
                t[i] = python_to_d!(typeof(arg))(pobj);
                Py_DECREF(pobj);
            }else static if(argNum == t.length) {
                alias Unqual!(ElementType!(typeof(t[i]))) elt_t;
                auto varlen = argCount-i;
                if(varlen == 1) {
                    auto  pobj = Py_XINCREF(PyTuple_GetItem(args, i));
                    if(PyList_Check(pobj)) {
                        try{
                            t[i] = cast(typeof(t[i])) python_to_d!(elt_t[])(pobj);
                        }catch(PythonException e) {
                            t[i] = cast(typeof(t[i])) [python_to_d!elt_t(pobj)];
                        }
                    }else{
                        t[i] = cast(typeof(t[i])) [python_to_d!elt_t(pobj)];
                    }
                    Py_DECREF(pobj);
                }else{
                    elt_t[] vars = new elt_t[](argCount-i);
                    foreach(j; i .. argCount) {
                        auto  pobj = Py_XINCREF(PyTuple_GetItem(args, j));
                        vars[j-i] = python_to_d!(elt_t)(pobj);
                        Py_DECREF(pobj);
                    }
                    t[i] = cast(typeof(t[i])) vars;
                }
                return fn(t);
                break;
            }
        }else static assert(0);
    }
    // This should never get here.
    throw new Exception("applyPyTupleToAlias reached end! argCount = " ~ to!string(argCount));
}

// wraps applyPyTupleToAlias to return a PyObject*
// kwargs may be null, args may not.
PyObject* pyApplyToAlias(alias fn, string fname) (PyObject* args, PyObject* kwargs) {
    static if (is(ReturnType!fn == void)) {
        applyPyTupleToAlias!(fn,fname)(args, kwargs);
        return Py_INCREF(Py_None());
    } else {
        return d_to_python( applyPyTupleToAlias!(fn,fname)(args, kwargs) );
    }
}

ReturnType!(dg_t) applyPyTupleToDelegate(dg_t) (dg_t dg, PyObject* args) {
    alias ParameterTypeTuple!(dg_t) T;
    enum size_t ARGS = T.length;
    alias ReturnType!(dg_t) RT;

    Py_ssize_t argCount = 0;
    // This can make it more convenient to call this with 0 args.
    if (args !is null) {
        argCount = PyObject_Length(args);
    }

    // Sanity check!
    if (!supportsNArgs!(dg,dg_t)(argCount)) {
        setWrongArgsError(argCount, ARGS, ARGS);
        handle_exception();
    }

    static if (ARGS == 0) {
        if (argCount == 0) {
            return dg();
        }
    }
    T t;
    foreach(i, arg; t) {
        auto pi = Py_XINCREF(PyTuple_GetItem(args, i));
        t[i] = python_to_d!(typeof(arg))(pi);
        Py_DECREF(pi);
    }
    return dg(t);
}

// wraps applyPyTupleToDelegate to return a PyObject*
PyObject* pyApplyToDelegate(dg_t) (dg_t dg, PyObject* args) {
    static if (is(ReturnType!(dg_t) == void)) {
        applyPyTupleToDelegate(dg, args);
        return Py_INCREF(Py_None());
    } else {
        return d_to_python( applyPyTupleToDelegate(dg, args) );
    }
}

template wrapped_func_call(fn_t) {
    enum size_t ARGS = ParameterTypeTuple!(fn_t).length;
    alias ReturnType!(fn_t) RT;
    // The entry for the tp_call slot of the PydFunc types.
    // (Or: What gets called when you pass a delegate or function pointer to
    // Python.)
    extern(C)
    PyObject* call(PyObject* self, PyObject* args, PyObject* kwds) {
        if (self is null) {
            PyErr_SetString(PyExc_TypeError, "Wrapped method didn't get a function pointer.");
            return null;
        }

        fn_t fn = (cast(wrapped_class_object!(fn_t)*)self).d_obj;

        return exception_catcher(delegate PyObject*() {
            return pyApplyToDelegate(fn, args);
        });
    }
}

// Wraps a function alias with a PyCFunctionWithKeywords.
template function_wrap(alias real_fn, string fnname) {
    alias ParameterTypeTuple!real_fn Info;
    enum size_t MAX_ARGS = Info.length;
    alias ReturnType!real_fn RT;

    extern (C)
    PyObject* func(PyObject* self, PyObject* args, PyObject* kwargs) {
        return exception_catcher(delegate PyObject*() {
            return pyApplyToAlias!(real_fn,fnname)(args, kwargs);
        });
    }
}

// Wraps a member function alias with a PyCFunction.
// func's args and kwargs may each be null.
template method_wrap(C, alias real_fn, string fname) {
    alias ParameterTypeTuple!real_fn Info;
    enum size_t ARGS = Info.length;
    alias ReturnType!real_fn RT;
    extern(C)
    PyObject* func(PyObject* self, PyObject* args, PyObject* kwargs) {
        return exception_catcher(delegate PyObject*() {
            // Didn't pass a "self" parameter! Ack!
            if (self is null) {
                PyErr_SetString(PyExc_TypeError, "Wrapped method didn't get a 'self' parameter.");
                return null;
            }
            C instance = (cast(wrapped_class_object!(C)*)self).d_obj;
            if (instance is null) {
                PyErr_SetString(PyExc_ValueError, "Wrapped class instance is null!");
                return null;
            }
            Py_ssize_t arglen = args is null ? 0 : PyObject_Length(args);
            enforce(arglen != -1);
            PyObject* self_and_args = PyTuple_New(arglen+1);
            scope(exit) {
                Py_XDECREF(self_and_args);
            }
            enforce(self_and_args);
            PyTuple_SetItem(self_and_args, 0, self);
            Py_INCREF(self);
            foreach(i; 0 .. arglen) {
                auto pobj = Py_XINCREF(PyTuple_GetItem(args, i));
                PyTuple_SetItem(self_and_args, i+1, pobj);
            }
            alias memberfunc_to_func!(C,real_fn).func func;
            return pyApplyToAlias!(func,fname)(self_and_args, kwargs);
        });
    }
}

template method_dgwrap(C, alias real_fn) {
    alias ParameterTypeTuple!real_fn Info;
    enum size_t ARGS = Info.length;
    alias ReturnType!real_fn RT;
    extern(C)
    PyObject* func(PyObject* self, PyObject* args) {
        return exception_catcher(delegate PyObject*() {
            // Didn't pass a "self" parameter! Ack!
            if (self is null) {
                PyErr_SetString(PyExc_TypeError, "Wrapped method didn't get a 'self' parameter.");
                return null;
            }
            C instance = (cast(wrapped_class_object!(C)*)self).d_obj;
            if (instance is null) {
                PyErr_SetString(PyExc_ValueError, "Wrapped class instance is null!");
                return null;
            }
            auto dg = dg_wrapper!(C, typeof(&real_fn))(instance, &real_fn);
            return pyApplyToDelegate(dg, args);
        });
    }
}


template memberfunc_to_func(T, alias memfn) {
    alias ReturnType!memfn Ret;
    enum params = getparams!memfn;
    alias ParameterTypeTuple!memfn PS;
    alias ParameterIdentifierTuple!memfn ids;
        
    mixin(Replace!(q{
        Ret func(T t, $params) {
            auto dg = dg_wrapper(t, &memfn);
            return dg($ids);
        }
    }, "$params", params, "$fn", __traits(identifier, memfn), 
       "$ids",Join!(",",ids)));

}

//-----------------------------------------------------------------------------
// And now the reverse operation: wrapping a Python callable with a delegate.
// These rely on a whole collection of nasty templates, but the result is both
// flexible and pretty fast.
// (Sadly, wrapping a Python callable with a regular function is not quite
// possible.)
//-----------------------------------------------------------------------------
// The steps involved when calling this function are as follows:
// 1) An instance of PydWrappedFunc is made, and the callable placed within.
// 2) The delegate type Dg is broken into its constituent parts.
// 3) These parts are used to get the proper overload of PydWrappedFunc.fn
// 4) A delegate to PydWrappedFunc.fn is returned.
// 5) When fn is called, it attempts to cram the arguments into the callable.
//    If Python objects to this, an exception is raised. Note that this means
//    any error in converting the callable to a given delegate can only be
//    detected at runtime.

Dg PydCallable_AsDelegate(Dg) (PyObject* c) {
    return _pycallable_asdgT!(Dg).func(c);
}

private template _pycallable_asdgT(Dg) {
    alias ParameterTypeTuple!(Dg) Info;
    alias ReturnType!(Dg) Tr;

    Dg func(PyObject* c) {
        auto f = new PydWrappedFunc(c);
        // compiler bug 7572 preventing
        // return &f.fn!(Tr,Info)
        // which is probably cleaner than
        return delegate Tr(Info i){return f.fn!(Tr, Info)(i);};
    }
}

private
class PydWrappedFunc {
    PyObject* callable;

    this(PyObject* c) { callable = c; Py_INCREF(c); }
    ~this() { Py_DECREF(callable); }

    Tr fn(Tr, T ...) (T t) {
        PyObject* ret = call(t);
        if (ret is null) handle_exception();
        scope(exit) Py_DECREF(ret);
        return python_to_d!(Tr)(ret);
    }

    PyObject* call(T ...) (T t) {
        enum size_t ARGS = T.length;
        PyObject* pyt = PyTuple_FromItems(t);
        if (pyt is null) return null;
        scope(exit) Py_DECREF(pyt);
        return PyObject_CallObject(callable, pyt);
    }
}

PyObject* arrangeNamedArgs(alias fn, string fname)(PyObject* args, PyObject* kwargs) {
    alias ParameterIdentifierTuple!fn ids;
    string[] allfnnames = new string[](ids.length);
    size_t[string] allfnnameset;
    foreach(i,id; ids) {
        allfnnames[i] = id;
        allfnnameset[id] = i;
    }
    alias variadicFunctionStyle!fn vstyle;
    size_t firstDefaultValueIndex = ids.length;
    static if(vstyle == Variadic.no) {
        alias ParameterDefaultValueTuple!fn Defaults;
        foreach(i, v; Defaults) {
            static if(!is(v == void)) {
                firstDefaultValueIndex = i;
                break;
            }
        }
    }

    Py_ssize_t arglen = PyObject_Length(args);
    enforce(arglen != -1);
    Py_ssize_t kwarglen = PyObject_Length(kwargs);
    enforce(kwarglen != -1);
    // variadic args might give us a count greater than ids.length
    // (but in that case there should be no kwargs)
    auto allargs = PyTuple_New(max(ids.length, arglen+kwarglen));

    foreach(i; 0 .. arglen) {
        auto pobj = Py_XINCREF(PyTuple_GetItem(args, i));
        PyTuple_SetItem(allargs, i, pobj);
    }
    PyObject* keys = PyDict_Keys(kwargs);
    enforce(keys);
    for(size_t _n = 0; _n < kwarglen; _n++) {
        PyObject* pkey = PySequence_GetItem(keys, _n);
        auto name = python_to_d!string(pkey);
        if(name !in allfnnameset) {
            enforce(false, format("%s() got an unexpected keyword argument '%s'",fname, name));
            

        }
        size_t n = allfnnameset[name];
        auto bval = PyDict_GetItem(kwargs, pkey);
        if(bval) {
            auto val = Py_XINCREF(bval);
            PyTuple_SetItem(allargs, n, val);
        }else if(vstyle == Variadic.no && n >= firstDefaultValueIndex) {
            // ok, we can get the default value 
        }else{
            enforce(false, format("argument '%s' is NULL! <%s, %s, %s, %s>", 
                        name, n, firstDefaultValueIndex, ids.length, 
                        vstyle == Variadic.no));
        }
    }
    Py_DECREF(keys);
    return allargs;
}

template minNumArgs_impl(alias fn, fnT) {
    alias ParameterTypeTuple!(fnT) Params;
    alias ParameterDefaultValueTuple!(fn) Defaults;
    alias variadicFunctionStyle!fn vstyle;
    static if(Params.length == 0) {
        // handle func(), func(...)
        enum res = 0;
    }else static if(vstyle == Variadic.typesafe){
        // handle func(nondefault T1 t1, nondefault T2 t2, etc, TN[]...)
        enum res = Params.length-1;
    }else {
        size_t count_nondefault() {
            size_t result = 0;
            foreach(i, v; Defaults) {
                static if(is(v == void)) {
                    result ++;
                }else break;
            }
            return result;
        }
        enum res = count_nondefault();
    }
}

/**
  Finds the minimal number of arguments a given function needs to be provided
 */
template minArgs(alias fn, fnT = typeof(&fn)) {
    enum size_t minArgs = minNumArgs_impl!(fn, fnT).res;
}

/**
  Finds the maximum number of arguments a given function may be provided
  and/or whether the function has a maximum number of arguments.
  */
template maxArgs(alias fn, fn_t = typeof(&fn)) {
    alias variadicFunctionStyle!fn vstyle;
    alias ParameterTypeTuple!fn ps;
    /// _
    enum bool hasMax = vstyle == Variadic.no;
    /// _
    enum size_t max = ps.length;
}

/**
  Determines at runtime whether the function can be given n arguments.
  */
bool supportsNArgs(alias fn, fn_t = typeof(&fn))(size_t n) {
    if(n < minArgs!(fn,fn_t)) {
        return false;
    }
    alias variadicFunctionStyle!fn vstyle;
    alias ParameterTypeTuple!fn ps;
    alias ParameterDefaultValueTuple!fn defaults;
    static if(vstyle == Variadic.no) {
        return (n >= minArgs!(fn,fn_t) && n <= maxArgs!(fn,fn_t).max);
    }else static if(vstyle == Variadic.c) {
        return true;
    }else static if(vstyle == Variadic.d) {
        return true;
    }else static if(vstyle == Variadic.typesafe) {
        return true;
    }else static assert(0);
}

/**
  Get the parameters of function as a string
Example:
---
void foo(int i, double j=2.0) {
}

static assert(getparams!foo == "int i, double j = 2");
---
  */
template getparams(alias fn) {
    enum raw_str = typeof(fn).stringof;
    enum ret_str = ReturnType!fn.stringof;
    enum iret = countUntil(raw_str, ret_str);
    static assert(iret != -1);
    static assert(countUntil(raw_str[0 .. iret], "(") == -1);
    enum noret_str = raw_str[iret + ret_str.length .. $];
    enum open_p = countUntil(noret_str, "(");
    static assert(open_p != -1);
    enum close_p = countUntil(retro(noret_str), ")");
    static assert(close_p != -1);
    enum getparams = noret_str[open_p+1 .. $-1-close_p];

}

/*
 * some more or less dirty hacks for converting
 * between function and delegate types. As of DMD 0.174, the language has
 * built-in support for hacking apart delegates like this. Hooray!
 */

template fn_to_dgT(Fn) {
    alias ParameterTypeTuple!(Fn) T;
    alias ReturnType!(Fn) Ret;

    alias Ret delegate(T) type;
}

/**
 * This template converts a function type into an equivalent delegate type.
 */
template fn_to_dg(Fn) {
    alias fn_to_dgT!(Fn).type fn_to_dg;
}

/**
 * This template function converts a pointer to a member function into a
 * delegate.
 */
auto dg_wrapper(T, Fn) (T t, Fn fn) {
    fn_to_dg!(Fn) dg;
    dg.ptr = cast(void*) t;
    static if(variadicFunctionStyle!fn == Variadic.typesafe) {
        // trying to stuff a Ret function(P[]...) into a Ret function(P[])
        // it'll totally work!
        dg.funcptr = cast(typeof(dg.funcptr)) fn;
    }else{
        dg.funcptr = fn;
    }

    return dg;
}

