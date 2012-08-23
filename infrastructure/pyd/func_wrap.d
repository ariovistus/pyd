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
module pyd.func_wrap;

import python;
import std.metastrings;
import std.exception: enforce;
import std.range: ElementType;

import pyd.class_wrap;
import pyd.dg_convert;
import pyd.exception;
import pyd.make_object;
import pyd.lib_abstract;

import std.traits;

// Builds a callable Python object from a delegate or function pointer.
void PydWrappedFunc_Ready(T)() {
    alias wrapped_class_type!(T) type;
    alias wrapped_class_object!(T) obj;
    if (!is_wrapped!(T)) {
        type.ob_type = PyType_Type_p;
        type.tp_basicsize = obj.sizeof;
        type.tp_name = "PydFunc";
        type.tp_flags = Py_TPFLAGS_DEFAULT;

        type.tp_call = &wrapped_func_call!(T).call;

        PyType_Ready(&type);
        is_wrapped!(T) = true;
        //wrapped_classes[typeid(T)] = true;
    }
}

void setWrongArgsError(Py_ssize_t gotArgs, size_t minArgs, size_t maxArgs, string funcName="") {

    string argStr(size_t args) {
        string temp = toString(args) ~ " argument";
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
    str ~= " (" ~ toString(gotArgs) ~ " given)";

    PyErr_SetString(PyExc_TypeError, (str ~ "\0").dup.ptr);
}

// Calls callable alias fn with PyTuple args.
ReturnType!(fn_t) applyPyTupleToAlias(alias fn, fn_t) 
    (PyObject* args, PyObject* kwargs) {
    alias ParameterTypeTuple!(fn_t) T;
    enum size_t MIN_ARGS = minArgs!fn;
    alias maxArgs!fn MaxArgs;
    alias ReturnType!(fn_t) RT;
    bool argsoverwrote = false;

    Py_ssize_t argCount = 0;
    // This can make it more convenient to call this with 0 args.
    if(kwargs !is null && PyObject_Length(kwargs) > 0) {
        args = arrangeNamedArgs!(fn)(args, kwargs);
        Py_ssize_t newlen = PyObject_Length(args);
        argsoverwrote = true;
    }
    scope(exit) if(argsoverwrote) Py_DECREF(args);
    if (args !is null) {
        argCount += PyObject_Length(args);
    }

    // Sanity check!
    if (!supportsNArgs!(fn, fn_t)(argCount)) {
        setWrongArgsError(cast(int) argCount, MIN_ARGS, 
                (MaxArgs.hasMax ? MaxArgs.max:-1));
        handle_exception();
    }

    static if (MaxArgs.vstyle == Variadic.no && MIN_ARGS == 0) {
        if (argCount == 0) {
            return fn();
        }
    }else{
        MaxArgs.ps t;
        foreach(i, arg; t) {
            enum size_t argNum = i+1;
            static if(MaxArgs.vstyle == Variadic.no) {
                if (i < argCount) {
                    auto bpobj =  PyTuple_GetItem(args, i);
                    enforce(bpobj != null);
                    auto  pobj = OwnPyRef(bpobj);
                    t[i] = d_type!(typeof(arg))(pobj);
                    Py_DECREF(pobj);
                }
                static if (argNum >= MIN_ARGS && 
                        (!MaxArgs.hasMax || argNum <= MaxArgs.max)) {
                    if (argNum == argCount) {
                        return fn(t[0 .. argNum]);
                        break;
                    }
                }
            }else static if(MaxArgs.vstyle == Variadic.typesafe) {
                if (argNum < t.length) {
                    auto bpobj =  PyTuple_GetItem(args, i);
                    enforce(bpobj != null);
                    auto  pobj = OwnPyRef(bpobj);
                    t[i] = d_type!(typeof(arg))(pobj);
                    Py_DECREF(pobj);
                }else if(argNum == t.length) {
                    alias Unqual!(ElementType!(typeof(t[i]))) elt_t;
                    auto varlen = argCount-i;
                    if(varlen == 1) {
                        auto bpobj =  PyTuple_GetItem(args, i);
                        enforce(bpobj != null);
                        auto  pobj = OwnPyRef(bpobj);
                        if(PyList_Check(pobj)) {
                            try{
                                t[i] = cast(typeof(t[i])) d_type!(elt_t[])(pobj);
                            }catch(PythonException e) {
                                t[i] = cast(typeof(t[i])) [d_type!elt_t(pobj)];
                            }
                        }else{
                            t[i] = cast(typeof(t[i])) [d_type!elt_t(pobj)];
                        }
                        Py_DECREF(pobj);
                    }else{
                        elt_t[] vars = new elt_t[](argCount-i);
                        foreach(j; i .. argCount) {
                            auto bpobj =  PyTuple_GetItem(args, j);
                            enforce(bpobj != null);
                            auto  pobj = OwnPyRef(bpobj);
                            vars[j-i] = d_type!(elt_t)(pobj);
                            Py_DECREF(pobj);
                        }
                        t[i] = cast(typeof(t[i])) vars;
                    }
                    return fn(t);
                    break;
                }
            }else static assert(0);
        }
    }
    // This should never get here.
    throw new Exception("applyPyTupleToAlias reached end! argCount = " ~ toString(argCount));
    static if (!is(RT == void))
        return ReturnType!(fn_t).init;
}

// wraps applyPyTupleToAlias to return a PyObject*
PyObject* pyApplyToAlias(alias fn, fn_t) (PyObject* args, PyObject* kwargs) {
    static if (is(ReturnType!(fn_t) == void)) {
        applyPyTupleToAlias!(fn, fn_t)(args, kwargs);
        Py_INCREF(Py_None);
        return Py_None;
    } else {
        return _py( applyPyTupleToAlias!(fn, fn_t)(args, kwargs) );
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
        auto pi = OwnPyRef(PyTuple_GetItem(args, i));
        t[i] = d_type!(typeof(arg))(pi);
        Py_DECREF(pi);
    }
    return dg(t);
}

// wraps applyPyTupleToDelegate to return a PyObject*
PyObject* pyApplyToDelegate(dg_t) (dg_t dg, PyObject* args) {
    static if (is(ReturnType!(dg_t) == void)) {
        applyPyTupleToDelegate(dg, args);
        Py_INCREF(Py_None);
        return Py_None;
    } else {
        return _py( applyPyTupleToDelegate(dg, args) );
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

// Wraps a function alias with a PyCFunction.
template function_wrap(alias real_fn, fn_t=typeof(&real_fn)) {
    alias ParameterTypeTuple!(fn_t) Info;
    enum size_t MAX_ARGS = Info.length;
    alias ReturnType!(fn_t) RT;

    extern (C)
    PyObject* func(PyObject* self, PyObject* args) {
        return exception_catcher(delegate PyObject*() {
            return pyApplyToAlias!(real_fn, fn_t)(args, null);
        });
    }
}

// Wraps a member function alias with a PyCFunction.
template method_wrap(C, alias real_fn, fn_t=typeof(&real_fn)) {
    alias ParameterTypeTuple!(fn_t) Info;
    enum size_t ARGS = Info.length;
    alias ReturnType!(fn_t) RT;
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
            fn_to_dg!(fn_t) dg = dg_wrapper!(C, fn_t)(instance, &real_fn);
            return pyApplyToDelegate(dg, args);
        });
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
        return d_type!(Tr)(ret);
    }

    PyObject* call(T ...) (T t) {
        enum size_t ARGS = T.length;
        PyObject* pyt = PyTuple_FromItems(t);
        if (pyt is null) return null;
        scope(exit) Py_DECREF(pyt);
        return PyObject_CallObject(callable, pyt);
    }
}


bool hasAllNamedArgs(alias fn)(Py_ssize_t arglen, PyObject* kwargs) {
    //static if(variadicFunctionStyle!fn != Variadic.no) return true;
    alias ParameterIdentifierTuple!fn ids;
    string[] sids = new string[](ids.length);
    bool[] flags = new bool[](ids.length);
    foreach(i,id; ids) sids[i] = id;
    PyObject* keys = PyDict_Keys(kwargs);
    Py_ssize_t len = PyObject_Length(keys);
FOREACH: 
    foreach(i; 0 .. len) {
        auto pobj = PySequence_GetItem(keys, i);
        enforce(pobj != null);
        string name = d_type!string(pobj);
        Py_DECREF(pobj);
        foreach(j,id; ids) {
            if(id == name && j >= arglen) {
                enforce(!flags[j]); // why would this happen? no idea.
                flags[j] = true;
                continue FOREACH;
            }
        }
        return false;
    }
    size_t firstmissing = -1;
    foreach(k,f; flags[arglen .. $]) {
        if(f && firstmissing != -1) {
            return false;
            //enforce(false, format("missing argument '%s'", sids[firstmissing]));
        }
        if(!f && firstmissing == -1) {
            firstmissing = k + arglen;
        }
    }
    return true;
}


PyObject* arrangeNamedArgs(alias fn)(PyObject* args, PyObject* kwargs) {
    alias ParameterIdentifierTuple!fn ids;
    string[] allfnnames = new string[](ids.length);
    foreach(i,id; ids) allfnnames[i] = id;

    Py_ssize_t arglen = PyObject_Length(args);
    enforce(arglen != -1);
    Py_ssize_t kwarglen = PyObject_Length(kwargs);
    enforce(kwarglen != -1);
    auto allargs = PyTuple_New(arglen+kwarglen);

    foreach(i; 0 .. arglen) {
        auto bobj = PyTuple_GetItem(args, i);
        enforce(bobj);
        auto pobj = OwnPyRef(bobj);
        PyTuple_SetItem(allargs, i, pobj);
        Py_DECREF(pobj);
    }

    foreach(n,name; allfnnames[arglen .. arglen + kwarglen]) {
        auto key = _py(name);
        auto bval = PyDict_GetItem(kwargs, key);
        enforce(bval);
        auto val = OwnPyRef(bval);
        PyTuple_SetItem(allargs, arglen+n, val);
        Py_DECREF(val);
    }
    return allargs;
}
