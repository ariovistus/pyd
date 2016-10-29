/*
Copyright 2006, 2007 Kirk McDonald

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
module pyd.make_wrapper;

import deimos.python.Python;

import util.typeinfo;
import util.replace: Replace;
import pyd.references;
import pyd.class_wrap;
import pyd.exception;
import pyd.func_wrap;
import std.traits;

template OverloadShim() {
    // If this is actually an instance of a Python subclass, return the
    // PyObject associated with the object. Otherwise, return null.
    PyObject* __pyd_get_pyobj() const {
        auto py = cast(PyObject*) get_python_reference(this);
        PyTypeObject** _pytype = this.classinfo in wrapped_classes;
        if (_pytype is null || py.ob_type != *_pytype) {
            return null;
        } else {
            return py;
        }
    }
    template __pyd_abstract_call(fn_t) {
        ReturnType!(fn_t) func(T ...) (string name, T t) {
            PyObject* _pyobj = this.__pyd_get_pyobj();
            if (_pyobj !is null) {
                PyObject* method = PyObject_GetAttrString(_pyobj, (name ~ "\0").dup.ptr);
                if (method is null) handle_exception();
                auto pydg = PydCallable_AsDelegate!(fn_to_dg!(fn_t))(method);
                Py_DECREF(method);
                return pydg(t);
            } else {
                PyErr_SetNone(PyExc_NotImplementedError);
                handle_exception();
                //return ReturnType!(fn_t).init;
            }
        }
    }
    template __pyd_get_overload(string realname, fn_t) {
        enum attrs = functionAttributes!fn_t;
            mixin(Replace!(q{
        ReturnType!(fn_t) func(T ...) (string name, T t) $constness $attrs {
            PyObject* _pyobj = this.__pyd_get_pyobj();
            if (_pyobj !is null) {
                // If this object's type is not the wrapped class's type (that is,
                // if this object is actually a Python subclass of the wrapped
                // class), then call the Python object.
                PyObject* method = PyObject_GetAttrString(_pyobj, (name ~ "\0").dup.ptr);
                if (method is null) handle_exception();
                auto pydg = PydCallable_AsDelegate!(fn_to_dg!(fn_t))(method);
                Py_DECREF(method);
                return pydg(t);
            } else {
                return super.$realname(t);
            }
        }
        }, "$constness",
            isImmutableFunction!fn_t ? "immutable" :
            isConstFunction!fn_t ? "const" : "",
            "$attrs", attrs_to_string(attrs),
            "$realname", realname));
    }
    int __pyd_apply_wrapper(dg_t) (dg_t dg) {
        alias ParameterTypeTuple!(dg_t)[0] arg_t;
        const uint args = ParameterTypeTuple!(dg_t).length;
        PyObject* _pyobj = this.__pyd_get_pyobj();
        if (_pyobj !is null) {
            PyObject* iter = PyObject_GetIter(_pyobj);
            if (iter is null) handle_exception();
            PyObject* item;
            int result = 0;

            item = PyIter_Next(iter);
            while (item) {
                static if (args == 1 && is(arg_t == PyObject*)) {
                    result = dg(item);
                } else {
                    if (PyTuple_Check(item)) {
                        result = applyPyTupleToDelegate(dg, item);
                    } else {
                        static if (args == 1) {
                            arg_t t = python_to_d!(typeof(arg_t))(item);
                            result = dg(t);
                        } else {
                            throw new Exception("Tried to override opApply with wrong number of args...");
                        }
                    }
                }
                Py_DECREF(item);
                if (result) break;
                item = PyIter_Next(iter);
            }
            Py_DECREF(iter);
            handle_exception();
            return result;
        } else {
            return super.opApply(dg);
        }
    }
}

template class_decls(uint i, T, Params...) {
    static if (i < Params.length) {
        enum string class_decls = Params[i].shim!(i,T) ~ class_decls!(i+1, T, Params);
    } else {
        enum string class_decls = "";
    }
}

template make_wrapper(T, Params...) {
    enum string cls =
    "class wrapper : T {\n"~
    "    mixin OverloadShim;\n"~
    pyd.make_wrapper.class_decls!(0, T, Params)~"\n"~
    "}\n";
    mixin(cls);
}

