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
import std.exception: enforce;
import std.range;
import std.conv;
import std.compiler;
import std.string: format;
import util.typelist;
import util.typeinfo;
import util.replace: Replace;

import pyd.def;
import pyd.references;
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

template StripFunctionAttributes(F) {
    static if(hasFunctionAttrs!F) {
        alias StripFunctionAttributes = SetFunctionAttributes!(F,
                functionLinkage!F,
                StrippedFunctionAttributes);
    }else{
        alias StripFunctionAttributes = F;
    }
}

static if(version_major == 2 && version_minor >= 67) {
    enum StrippedFunctionAttributes = FunctionAttribute.system;
}else{
    enum StrippedFunctionAttributes = FunctionAttribute.none;
}

// Builds a callable Python object from a delegate or function pointer.
void PydWrappedFunc_Ready(S)() {
    alias T = StripFunctionAttributes!S;
    alias PydTypeObject!(T) type;
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

// compose a tuple without cast-breaking constness
// example:
// ----------
// alias TupleComposer!(immutable(int), immutable(string)) T1;
// T1* t = new T1(1);
// t = t.put!1("foo");
// // t.fields is a thing now
struct TupleComposer(Ts...) {
    Ts fields;

    TupleComposer!Ts* put(size_t i)(Ts[i] val) {
        static if(isAssignable!(Ts[i])) {
            fields[i] = val;
            return &this;
        }else{
            return new TupleComposer(fields[0 .. i], val);
        }

    }
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
    auto t = new TupleComposer!(MaxArgs.ps)();
    foreach(i, arg; t.fields) {
        enum size_t argNum = i+1;
        static if(MaxArgs.vstyle == Variadic.no) {
			//https://issues.dlang.org/show_bug.cgi?id=17192
			//alias ParameterDefaultValueTuple!fn Defaults;
			import util.typeinfo : WorkaroundParameterDefaults;
			alias Defaults = WorkaroundParameterDefaults!fn;
            if (i < argCount) {
                auto bpobj =  PyTuple_GetItem(args, cast(Py_ssize_t) i);
                if(bpobj) {
                    auto pobj = Py_XINCREF(bpobj);
                    t = t.put!i(python_to_d!(typeof(arg))(pobj));
                    Py_DECREF(pobj);
                }else{
                    static if(!is(Defaults[i] == void)) {
                        t = t.put!i(Defaults[i]);
                    }else{
                        // should never happen
                        enforce(0, "python non-keyword arg is NULL!");
                    }
                }
            }
            static if (argNum >= MIN_ARGS &&
                    (!MaxArgs.hasMax || argNum <= MaxArgs.max)) {
                if (argNum == argCount) {
                    return fn(t.fields[0 .. argNum]);
                }
            }
        }else static if(MaxArgs.vstyle == Variadic.typesafe) {
            static if (argNum < t.fields.length) {
                auto pobj = Py_XINCREF(PyTuple_GetItem(args, cast(Py_ssize_t) i));
                t = t.put!i(python_to_d!(typeof(arg))(pobj));
                Py_DECREF(pobj);
            }else static if(argNum == t.fields.length) {
                alias Unqual!(ElementType!(typeof(t.fields[i]))) elt_t;
                auto varlen = argCount-i;
                if(varlen == 1) {
                    auto  pobj = Py_XINCREF(PyTuple_GetItem(args, cast(Py_ssize_t) i));
                    if(PyList_Check(pobj)) {
                        try{
                            t = t.put!i(cast(typeof(t.fields[i])) python_to_d!(elt_t[])(pobj));
                        }catch(PythonException e) {
                            t = t.put!i(cast(typeof(t.fields[i])) [python_to_d!elt_t(pobj)]);
                        }
                    }else{
                        t = t.put!i(cast(typeof(t.fields[i])) [python_to_d!elt_t(pobj)]);
                    }
                    Py_DECREF(pobj);
                }else{
                    elt_t[] vars = new elt_t[](argCount-i);
                    foreach(j; i .. argCount) {
                        auto  pobj = Py_XINCREF(PyTuple_GetItem(args, cast(Py_ssize_t) j));
                        vars[j-i] = python_to_d!(elt_t)(pobj);
                        Py_DECREF(pobj);
                    }
                    t = t.put!i(cast(typeof(t.fields[i])) vars);
                }
                return fn(t.fields);
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
        auto pi = Py_XINCREF(PyTuple_GetItem(args, cast(Py_ssize_t) i));
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

        return exception_catcher(delegate PyObject*() {
            fn_t fn = get_d_reference!fn_t(self);
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
            import thread = pyd.thread;
            thread.ensureAttached();
            return pyApplyToAlias!(real_fn,fnname)(args, kwargs);
        });
    }
}

// Wraps a member function alias with a PyCFunction.
// func's args and kwargs may each be null.
template method_wrap(C, alias real_fn, string fname) {
    static assert(constCompatible(constness!C, constness!(typeof(real_fn))),
            format("constness mismatch instance: %s function: %s",
                C.stringof, typeof(real_fn).stringof));
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
            C instance = get_d_reference!C(self);
            if (instance is null) {
                PyErr_SetString(PyExc_ValueError, "Wrapped class instance is null!");
                return null;
            }

            Py_ssize_t arglen = args is null ? 0 : PyObject_Length(args);
            enforce(arglen != -1);
            PyObject* self_and_args = PyTuple_New(cast(Py_ssize_t) arglen+1);
            scope(exit) {
                Py_XDECREF(self_and_args);
            }
            enforce(self_and_args);
            PyTuple_SetItem(self_and_args, 0, self);
            Py_INCREF(self);
            foreach(i; 0 .. arglen) {
                auto pobj = Py_XINCREF(PyTuple_GetItem(args, cast(Py_ssize_t) i));
                PyTuple_SetItem(self_and_args, cast(Py_ssize_t) i+1, pobj);
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
            C instance = get_d_reference!C(self);
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
    alias ParameterTypeTuple!memfn PS;
    alias ParameterIdentifierTuple!memfn ids;
	//https://issues.dlang.org/show_bug.cgi?id=17192
    //alias ParameterDefaultValueTuple!memfn dfs;
	import util.typeinfo : WorkaroundParameterDefaults;
    alias dfs = WorkaroundParameterDefaults!memfn;
    enum params = getparams!(memfn,"PS","dfs");
    enum t = gensym!ids();

    mixin(Replace!(q{
        Ret func(T $t, $params) {
            auto dg = dg_wrapper($t, &memfn);
            return dg($ids);
        }
    }, "$params", params, "$fn", __traits(identifier, memfn), "$t",t,
       "$ids",Join!(",",ids)));

}

string gensym(Taken...)() {
    bool ok(string s) {
        bool _ok = true;
        foreach(t; Taken) {
            if(s == t) _ok = false;
        }
        return _ok;
    }
    foreach(c; 'a' .. 'z'+1) {
        string s = to!string(cast(char)c);
        if (ok(s)) return s;
    }
    // teh heck? wat kind of function takes more than 26 user-typed params?
    int i = 0;
    while(true) {
        string s = format("_%s",i);
        if (ok(s)) return s;
        i++;
    }
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

private template _pycallable_asdgT(Dg) if(is(Dg == delegate)) {
    alias ParameterTypeTuple!(Dg) Info;
    alias ReturnType!(Dg) Tr;

    Dg func(PyObject* c) {
        static if(isImmutableFunction!Dg) {
            auto f = cast(immutable) new PydWrappedFunc(c);
            return &f.fn_i!(Tr,Info);
        }else static if(isConstFunction!Dg) {
            auto f = new const(PydWrappedFunc)(c);
            return &f.fn_c!(Tr,Info);
        }else{
            auto f = new PydWrappedFunc(c);
            return &f.fn!(Tr,Info);
        }
    }
}

private
class PydWrappedFunc {
    PyObject* callable;

    this(PyObject* c) {
        callable = c;
        Py_INCREF(c);
    }

    ~this() {
        if(callable && !Py_Finalize_called) {
            Py_DECREF(callable);
        }
        callable = null;
    }

    Tr fn(Tr, T ...) (T t) {
        PyObject* ret = call(t);
        if (ret is null) handle_exception();
        scope(exit) Py_DECREF(ret);
        return python_to_d!(Tr)(ret);
    }
    Tr fn_c(Tr, T ...) (T t) const {
        PyObject* ret = call_c(t);
        if (ret is null) handle_exception();
        scope(exit) Py_DECREF(ret);
        return python_to_d!(Tr)(ret);
    }
    Tr fn_i(Tr, T ...) (T t) immutable {
        PyObject* ret = call_i(t);
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
    PyObject* call_c(T ...) (T t) const {
        enum size_t ARGS = T.length;
        PyObject* pyt = PyTuple_FromItems(t);
        if (pyt is null) return null;
        scope(exit) Py_DECREF(pyt);
        return PyObject_CallObject(cast(PyObject*) callable, pyt);
    }
    PyObject* call_i(T ...) (T t) immutable {
        enum size_t ARGS = T.length;
        PyObject* pyt = PyTuple_FromItems(t);
        if (pyt is null) return null;
        scope(exit) Py_DECREF(pyt);
        return PyObject_CallObject(cast(PyObject*) callable, pyt);
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
        //https://issues.dlang.org/show_bug.cgi?id=17192
        //alias ParameterDefaultValueTuple!fn Defaults;
		import util.typeinfo : WorkaroundParameterDefaults;
        alias Defaults = WorkaroundParameterDefaults!fn;
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
    auto allargs = PyTuple_New(cast(Py_ssize_t)
            max(ids.length, arglen+kwarglen));

    foreach(i; 0 .. arglen) {
        auto pobj = Py_XINCREF(PyTuple_GetItem(args, cast(Py_ssize_t) i));
        PyTuple_SetItem(allargs, cast(Py_ssize_t) i, pobj);
    }
    PyObject* keys = PyDict_Keys(kwargs);
    enforce(keys);
    for(size_t _n = 0; _n < kwarglen; _n++) {
        PyObject* pkey = PySequence_GetItem(keys, cast(Py_ssize_t) _n);
        auto name = python_to_d!string(pkey);
        if(name !in allfnnameset) {
            enforce(false, format("%s() got an unexpected keyword argument '%s'",fname, name));


        }
        size_t n = allfnnameset[name];
        auto bval = PyDict_GetItem(kwargs, pkey);
        if(bval) {
            auto val = Py_XINCREF(bval);
            PyTuple_SetItem(allargs, cast(Py_ssize_t) n, val);
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
	//https://issues.dlang.org/show_bug.cgi?id=17192
    //alias ParameterDefaultValueTuple!(fn) Defaults;
	import util.typeinfo : WorkaroundParameterDefaults;
	alias Defaults = WorkaroundParameterDefaults!fn;
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
	//https://issues.dlang.org/show_bug.cgi?id=17192
    //alias ParameterDefaultValueTuple!fn defaults;
	import util.typeinfo : WorkaroundParameterDefaults;
	alias defaults = WorkaroundParameterDefaults!fn;
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
  Get the parameters of function as a string.

  pt_alias refers to an alias of ParameterTypeTuple!fn
  visible to wherever you want to mix in the results.
  pd_alias refers to an alias of ParameterDefaultValueTuple!fn
  visible to wherever you want to mix in the results.
Example:
---
void foo(int i, int j=2) {
}

static assert(getparams!(foo,"P","Pd") == "P[0] i, P[1] j = Pd[1]");
---
  */
template getparams(alias fn, string pt_alias, string pd_alias) {
    alias ParameterIdentifierTuple!fn Pi;
    //https://issues.dlang.org/show_bug.cgi?id=17192
    //alias ParameterDefaultValueTuple!fn Pd;
    import util.typeinfo : WorkaroundParameterDefaults;
    alias Pd = WorkaroundParameterDefaults!fn;
    enum var = variadicFunctionStyle!fn;

    string inner() {
        static if(var == Variadic.c || var == Variadic.d) {
            return "...";
        }else{
            string ret = "";
            foreach(size_t i, id; Pi) {
                ret ~= format("%s[%s] %s", pt_alias, i, id);
                static if(!is(Pd[i] == void)) {
                    ret ~= format(" = %s[%s]", pd_alias, i);
                }
                static if(i != Pi.length-1) {
                    ret ~= ", ";
                }
            }
            static if(var == Variadic.typesafe) {
                ret ~= "...";
            }
            return ret;
        }
    }

    enum getparams = inner();

}

template isImmutableFunction(T...) if (T.length == 1) {
    alias funcTarget!T func_t;
    enum isImmutableFunction = is(func_t == immutable);
}
template isConstFunction(T...) if (T.length == 1) {
    alias funcTarget!T func_t;
    enum isConstFunction = is(func_t == const);
}
template isMutableFunction(T...) if (T.length == 1) {
    alias funcTarget!T func_t;
    enum isMutableFunction = !is(func_t == inout) && !is(func_t == const) && !is(func_t == immutable);
}
template isWildcardFunction(T...) if (T.length == 1) {
    alias funcTarget!T func_t;
    enum isWildcardFunction = is(func_t == inout);
}
template isSharedFunction(T...) if (T.length == 1) {
    alias funcTarget!T func_t;
    enum isSharedFunction = is(func_t == shared);
}

template funcTarget(T...) if(T.length == 1) {
    static if(isPointer!(T[0]) && is(PointerTarget!(T[0]) == function)) {
        alias PointerTarget!(T[0]) funcTarget;
    }else static if(is(T[0] == function)) {
        alias T[0] funcTarget;
    }else static if(is(T[0] == delegate)) {
        alias PointerTarget!(typeof((T[0]).init.funcptr)) funcTarget;
    }else static assert(false);
}

string tattrs_to_string(fn_t)() {
    string s;
    if(isConstFunction!fn_t) {
        s ~= " const";
    }
    if(isImmutableFunction!fn_t) {
        s ~= " immutable";
    }
    if(isSharedFunction!fn_t) {
        s ~= " shared";
    }
    if(isWildcardFunction!fn_t) {
        s ~= " inout";
    }
    return s;
}

bool constnessMatch2(fn...)(Constness c) if(fn.length == 1) {
    static if(isImmutableFunction!(fn)) return c == Constness.Immutable;
    static if(isMutableFunction!(fn)) return c == Constness.Mutable;
    static if(isConstFunction!(fn)) return c != Constness.Wildcard;
    else return false;
}

/*
 * some more or less dirty hacks for converting
 * between function and delegate types. As of DMD 0.174, the language has
 * built-in support for hacking apart delegates like this. Hooray!
 */

template fn_to_dgT(Fn) {
    alias ParameterTypeTuple!(Fn) T;
    alias ReturnType!(Fn) Ret;

    mixin("alias Ret delegate(T) " ~ tattrs_to_string!(Fn)() ~ " type;");
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

