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
module pyd.op_wrap;

import deimos.python.Python;

import std.algorithm: startsWith, endsWith;
import std.traits;
import std.exception: enforce;
import std.string: format;
import std.conv: to;
import util.typeinfo;

import pyd.references;
import pyd.class_wrap;
import pyd.func_wrap;
import pyd.exception;
import pyd.make_object;

// wrap a binary operator overload, handling __op__, __rop__, or
// __op__ and __rop__ as necessary.
// use new style operator overloading (ie check which arg is actually self).
// _lop.C is a tuple w length 0 or 1 containing a BinaryOperatorX instance.
// same for _rop.C.
template binop_wrap(T, _lop, _rop) {
    alias _lop.C lop;
    alias _rop.C rop;
    alias PydTypeObject!T wtype;
    static if(lop.length) {
        alias lop[0] lop0;
        alias lop0.Inner!T.FN lfn;
        alias dg_wrapper!(T, typeof(&lfn)) get_dgl;
        alias ParameterTypeTuple!(lfn)[0] LOtherT;
        alias ReturnType!(lfn) LRet;
    }
    static if(rop.length) {
        alias rop[0] rop0;
        alias rop0.Inner!T.FN rfn;
        alias dg_wrapper!(T, typeof(&rfn)) get_dgr;
        alias ParameterTypeTuple!(rfn)[0] ROtherT;
        alias ReturnType!(rfn) RRet;
    }
    enum mode = (lop.length?"l":"")~(rop.length?"r":"");
    extern(C)
    PyObject* func(PyObject* o1, PyObject* o2) {
        return exception_catcher(delegate PyObject*() {
                enforce(is_wrapped!(T));

                static if(mode == "lr") {
                    if (PyObject_IsInstance(o1, cast(PyObject*)&wtype)) {
                        goto op;
                    }else if(PyObject_IsInstance(o2, cast(PyObject*)&wtype)) {
                        goto rop;
                    }else{
                        enforce(false, format(
                            "unsupported operand type(s) for %s: '%s' and '%s'",
                            lop[0].op, to!string(o1.ob_type.tp_name),
                            to!string(o2.ob_type.tp_name),
                        ));
                    }
                }
                static if(mode.startsWith("l")) {
op:
                    auto dgl = get_dgl(get_d_reference!T(o1), &lfn);
                    static if(lop[0].op.endsWith("=")) {
                        dgl(python_to_d!LOtherT(o2));
                        // why?
                        // http://stackoverflow.com/questions/11897597/implementing-nb-inplace-add-results-in-returning-a-read-only-buffer-object
                        // .. still don't know
                        Py_INCREF(o1);
                        return o1;
                    }else static if (is(LRet == void)) {
                        dgl(python_to_d!LOtherT(o2));
                        return Py_INCREF(Py_None());
                    } else {
                        return d_to_python(dgl(python_to_d!LOtherT(o2)));
                    }
                }
                static if(mode.endsWith("r")) {
rop:
                    auto dgr = get_dgr(get_d_reference!T(o2), &rfn);
                    static if (is(RRet == void)) {
                        dgr(python_to_d!ROtherT(o1));
                        return Py_INCREF(Py_None());
                    } else {
                        return d_to_python(dgr(python_to_d!LOtherT(o1)));
                    }
                }
        });
    }
}

template binopasg_wrap(T, alias fn) {
    alias PydTypeObject!T wtype;
    alias dg_wrapper!(T, typeof(&fn)) get_dg;
    alias ParameterTypeTuple!(fn)[0] OtherT;
    alias ReturnType!(fn) Ret;

    extern(C)
    PyObject* func(PyObject* self, PyObject* o2) {
        auto dg = get_dg(get_d_reference!T(self), &fn);
        dg(python_to_d!OtherT(o2));
        // why?
        // http://stackoverflow.com/questions/11897597/implementing-nb-inplace-add-results-in-returning-a-read-only-buffer-object
        // .. still don't know
        Py_INCREF(self);
        return self;
    }
}

// pow is special. its stupid slot is a ternary function.
template powop_wrap(T, _lop, _rop) {
    alias _lop.C lop;
    alias _rop.C rop;
    alias PydTypeObject!T wtype;
    static if(lop.length) {
        alias lop[0] lop0;
        alias lop0.Inner!T.FN lfn;
        alias dg_wrapper!(T, typeof(&lfn)) get_dgl;
        alias ParameterTypeTuple!(lfn)[0] LOtherT;
        alias ReturnType!(lfn) LRet;
    }
    static if(rop.length) {
        alias rop[0] rop0;
        alias rop0.Inner!T.FN rfn;
        alias dg_wrapper!(T, typeof(&rfn)) get_dgr;
        alias ParameterTypeTuple!(rfn)[0] ROtherT;
        alias ReturnType!(rfn) RRet;
    }
    enum mode = (lop.length?"l":"")~(rop.length?"r":"");
    extern(C)
    PyObject* func(PyObject* o1, PyObject* o2, PyObject* o3) {
        return exception_catcher(delegate PyObject*() {
                enforce(is_wrapped!(T));

                static if(mode == "lr") {
                    if (PyObject_IsInstance(o1, cast(PyObject*)&wtype)) {
                        goto op;
                    }else if(PyObject_IsInstance(o2, cast(PyObject*)&wtype)) {
                        goto rop;
                    }else{
                        enforce(false, format(
                            "unsupported operand type(s) for %s: '%s' and '%s'",
                            opl.op, o1.ob_type.tp_name, o2.ob_type.tp_name,
                        ));
                    }
                }
                static if(mode.startsWith("l")) {
op:
                    auto dgl = get_dgl(get_d_reference!T(o1), &lfn);
                    static if (is(LRet == void)) {
                        dgl(python_to_d!LOtherT(o2));
                        return Py_INCREF(Py_None());
                    } else {
                        return d_to_python(dgl(python_to_d!LOtherT(o2)));
                    }
                }
                static if(mode.endsWith("r")) {
rop:
                    auto dgr = get_dgr(get_d_reference!T(o2), &rfn);
                    static if (is(RRet == void)) {
                        dgr(python_to_d!ROtherT(o1));
                        return Py_INCREF(Py_None());
                    } else {
                        return d_to_python(dgr(python_to_d!LOtherT(o1)));
                    }
                }
        });
    }
}

template powopasg_wrap(T, alias fn) {
    alias PydTypeObject!T wtype;
    alias dg_wrapper!(T, typeof(&fn)) get_dg;
    alias ParameterTypeTuple!(fn)[0] OtherT;
    alias ReturnType!(fn) Ret;

    extern(C)
    PyObject* func(PyObject* self, PyObject* o2, PyObject* o3) {
        auto dg = get_dg(get_d_reference!T(self), &fn);
        dg(python_to_d!OtherT(o2));
        // why?
        // http://stackoverflow.com/questions/11897597/implementing-nb-inplace-add-results-in-returning-a-read-only-buffer-object
        // .. still don't know
        Py_INCREF(self);
        return self;
    }
}

template opcall_wrap(T, alias fn) {
    static assert(constCompatible(constness!T, constness!(typeof(fn))),
            format("constness mismatch instance: %s function: %s",
                T.stringof, typeof(fn).stringof));
    alias PydTypeObject!T wtype;
    alias dg_wrapper!(T, typeof(&fn)) get_dg;
    alias ParameterTypeTuple!(fn)[0] OtherT;
    alias ReturnType!(fn) Ret;

    extern(C)
    PyObject* func(PyObject* self, PyObject* args, PyObject* kwargs) {
        return exception_catcher(delegate PyObject*() {
            // Didn't pass a "self" parameter! Ack!
            if (self is null) {
                PyErr_SetString(PyExc_TypeError, "OpCall didn't get a 'self' parameter.");
                return null;
            }
            T instance = get_d_reference!T(self);
            if (instance is null) {
                PyErr_SetString(PyExc_ValueError, "Wrapped class instance is null!");
                return null;
            }
            auto dg = get_dg(instance, &fn);
            return pyApplyToDelegate(dg, args);
        });
    }
}

//----------------//
// Implementation //
//----------------//

template opfunc_unary_wrap(T, alias opfn) {
    extern(C)
    PyObject* func(PyObject* self) {
        // method_dgwrap takes care of exception handling
        return method_dgwrap!(T, opfn).func(self, null);
    }
}

template opiter_wrap(T, alias fn){
    alias ParameterTypeTuple!fn params;
    extern(C)
    PyObject* func(PyObject* self) {
        alias memberfunc_to_func!(T,fn).func func;
        return exception_catcher(delegate PyObject*() {
            T t = python_to_d!T(self);
            auto dg = dg_wrapper(t, &fn);
            return d_to_python(dg());
        });
    }
}

template opindex_wrap(T, alias fn) {
    alias ParameterTypeTuple!fn Params;
    alias dg_wrapper!(T, typeof(&fn)) get_dg;

    // Multiple arguments are converted into tuples, and thus become a standard
    // wrapped member function call. A single argument is passed directly.
    static if (Params.length == 1) {
        alias Params[0] KeyT;
        extern(C)
        PyObject* func(PyObject* self, PyObject* key) {
            return exception_catcher(delegate PyObject*() {
                auto dg = get_dg(get_d_reference!T(self), &fn);
                return d_to_python(dg(python_to_d!KeyT(key)));
            });
        }
    } else {
        alias method_dgwrap!(T, fn) opindex_methodT;
        extern(C)
        PyObject* func(PyObject* self, PyObject* key) {
            Py_ssize_t args;
            if (!PyTuple_CheckExact(key)) {
                args = 1;
            } else {
                args = PySequence_Length(key);
            }
            if (Params.length != args) {
                setWrongArgsError(args, Params.length, Params.length);
                return null;
            }
            return opindex_methodT.func(self, key);
        }
    }
}

template opindexassign_wrap(T, alias fn) {
    alias ParameterTypeTuple!(fn) Params;

    static if (Params.length > 2) {
        alias method_dgwrap!(T, fn) fn_wrap;
        extern(C)
        int func(PyObject* self, PyObject* key, PyObject* val) {
            Py_ssize_t args;
            if (!PyTuple_CheckExact(key)) {
                args = 2;
            } else {
                args = PySequence_Length(key) + 1;
            }
            if (Params.length != args) {
                setWrongArgsError(args, Params.length, Params.length);
                return -1;
            }
            // Build a new tuple with the value at the front.
            PyObject* temp = PyTuple_New(Params.length);
            if (temp is null) return -1;
            scope(exit) Py_DECREF(temp);
            PyTuple_SetItem(temp, 0, val);
            for (int i=1; i<Params.length; ++i) {
                Py_INCREF(PyTuple_GetItem(key, i-1));
                PyTuple_SetItem(temp, i, PyTuple_GetItem(key, i-1));
            }
            fnwrap.func(self, temp);
            return 0;
        }
    } else {
        alias dg_wrapper!(T, typeof(&fn)) get_dg;
        alias Params[0] ValT;
        alias Params[1] KeyT;

        extern(C)
        int func(PyObject* self, PyObject* key, PyObject* val) {
            return exception_catcher(delegate int() {
                auto dg = get_dg(get_d_reference!T(self), &fn);
                dg(python_to_d!ValT(val), python_to_d!KeyT(key));
                return 0;
            });
        }
    }
}

template inop_wrap(T, _lop, _rop) {
    alias _rop.C rop;
    static if(rop.length) {
        alias rop[0] rop0;
        alias rop0.Inner!T.FN rfn;
        alias dg_wrapper!(T, typeof(&rfn)) get_dgr;
        alias ParameterTypeTuple!(rfn)[0] ROtherT;
    }

    extern(C)
    int func(PyObject* o1, PyObject* o2) {
        return exception_catcher(delegate int() {
            auto dg = get_dgr(get_d_reference!T(o1), &rfn);
            return dg(python_to_d!ROtherT(o2));
        });
    }
}

template opcmp_wrap(T, alias fn) {
    static assert(constCompatible(constness!T, constness!(typeof(fn))),
            format("constness mismatch instance: %s function: %s",
                T.stringof, typeof(fn).stringof));
    alias ParameterTypeTuple!(fn) Info;
    alias Info[0] OtherT;
    extern(C)
    int func(PyObject* self, PyObject* other) {
        return exception_catcher(delegate int() {
            int result = get_d_reference!T(self).opCmp(python_to_d!OtherT(other));
            // The Python API reference specifies that tp_compare must return
            // -1, 0, or 1. The D spec says opCmp may return any integer value,
            // and just compares it with zero.
            if (result < 0) return -1;
            if (result == 0) return 0;
            if (result > 0) return 1;
            assert(0);
        });
    }
}

template rich_opcmp_wrap(T, alias fn) {
    static assert(constCompatible(constness!T, constness!(typeof(fn))),
            format("constness mismatch instance: %s function: %s",
                T.stringof, typeof(fn).stringof));
    alias ParameterTypeTuple!(fn) Info;
    alias dg_wrapper!(T, typeof(&fn)) get_dg;
    alias Info[0] OtherT;
    extern(C)
    PyObject* func(PyObject* self, PyObject* other, int op) {
        return exception_catcher(delegate PyObject*() {
            auto dg = get_dg(get_d_reference!T(self), &fn);
            auto dother = python_to_d!OtherT(other);
            int result = dg(dother);
            bool pyresult;
            switch(op) {
                case Py_LT:
                    pyresult = (result < 0);
                    break;
                case Py_LE:
                    pyresult = (result <= 0);
                    break;
                case Py_EQ:
                    pyresult = (result == 0);
                    break;
                case Py_NE:
                    pyresult = (result != 0);
                    break;
                case Py_GT:
                    pyresult = (result > 0);
                    break;
                case Py_GE:
                    pyresult = (result >= 0);
                    break;
                default:
                    assert(0);
            }
            if (pyresult) return Py_INCREF(Py_True);
            else return Py_INCREF(Py_False);
        });
    }
}

//----------//
// Dispatch //
//----------//
template length_wrap(T, alias fn) {
    alias dg_wrapper!(T, typeof(&fn)) get_dg;
    extern(C)
    Py_ssize_t func(PyObject* self) {
        return exception_catcher(delegate Py_ssize_t() {
            auto dg = get_dg(get_d_reference!T(self), &fn);
            return dg();
        });
    }
}

template opslice_wrap(T,alias fn) {
    alias dg_wrapper!(T, typeof(&fn)) get_dg;
    extern(C)
    PyObject* func(PyObject* self, Py_ssize_t i1, Py_ssize_t i2) {
        return exception_catcher(delegate PyObject*() {
            auto dg = get_dg(get_d_reference!T(self), &fn);
            return d_to_python(dg(i1, i2));
        });
    }
}

template opsliceassign_wrap(T, alias fn) {
    alias ParameterTypeTuple!fn Params;
    alias Params[0] AssignT;
    alias dg_wrapper!(T, typeof(&fn)) get_dg;

    extern(C)
    int func(PyObject* self, Py_ssize_t i1, Py_ssize_t i2, PyObject* o) {
        return exception_catcher(delegate int() {
            auto dg = get_dg(get_d_reference!T(self), &fn);
            dg(python_to_d!AssignT(o), i1, i2);
            return 0;
        });
    }
}

