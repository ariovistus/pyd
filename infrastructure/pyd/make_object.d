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

/++
  This module contains some useful type conversion functions. There are two
  interesting operations involved here:
 
  d_type_: PyObject* -> D type 
 
  __py/py: D type -> PyObject*/PydObject 
 
  The former is handled by d_type, the latter by _py. The py function is
  provided as a convenience to directly convert a D type into an instance of
  PydObject.
 +/
module pyd.make_object;

import python;

import std.algorithm: endsWith;
import std.complex;
import std.bigint;
import std.traits;
import std.typecons: Tuple, tuple, isTuple;
import std.metastrings;
import std.conv;
import std.range;

import pyd.pydobject;
import pyd.class_wrap;
import pyd.func_wrap;
import pyd.exception;

class to_conversion_wrapper(dg_t) {
    alias ParameterTypeTuple!(dg_t)[0] T;
    alias ReturnType!(dg_t) Intermediate;
    dg_t dg;
    this(dg_t fn) { dg = fn; }
    PyObject* opCall(T t) {
        static if (is(Intermediate == PyObject*)) {
            return dg(t);
        } else {
            return _py(dg(t));
        }
    }
}
class from_conversion_wrapper(dg_t) {
    alias ParameterTypeTuple!(dg_t)[0] Intermediate;
    alias ReturnType!(dg_t) T;
    dg_t dg;
    this(dg_t fn) { dg = fn; }
    T opCall(PyObject* o) {
        static if (is(Intermediate == PyObject*)) {
            return dg(o);
        } else {
            return dg(d_type!(Intermediate)(o));
        }
    }
}

template to_converter_registry(From) {
    PyObject* delegate(From) dg=null;
}
template from_converter_registry(To) {
    To delegate(PyObject*) dg=null;
}

void d_to_python(dg_t) (dg_t dg) {
    static if (is(dg_t == delegate) && is(ReturnType!(dg_t) == PyObject*)) {
        to_converter_registry!(ParameterTypeTuple!(dg_t)[0]).dg = dg;
    } else {
        auto o = new to_conversion_wrapper!(dg_t)(dg);
        to_converter_registry!(typeof(o).T).dg = &o.opCall;
    }
}
void python_to_d(dg_t) (dg_t dg) {
    static if (is(dg_t == delegate) && is(ParameterTypeTuple!(dg_t)[0] == PyObject*)) {
        from_converter_registry!(ReturnType!(dg_t)).dg = dg;
    } else {
        auto o = new from_conversion_wrapper!(dg_t)(dg);
        from_converter_registry!(typeof(o).T).dg = &o.opCall;
    }
}

/**
 * Returns a new (owned) reference to a Python object based on the passed
 * argument. If the passed argument is a PyObject*, this "steals" the
 * reference. (In other words, it returns the PyObject* without changing its
 * reference count.) If the passed argument is a PydObject, this returns a new
 * reference to whatever the PydObject holds a reference to.
 *
 * If the passed argument can't be converted to a PyObject, a Python
 * RuntimeError will be raised and this function will return null.
 */
PyObject* _py(T) (T t) {
    static if (!is(T == PyObject*) && is(typeof(t is null)) &&
            !isAssociativeArray!T && !isArray!T) {
        if (t is null) {
            Py_INCREF(Py_None);
            return Py_None;
        }
    }
    static if (isBoolean!T) {
        PyObject* temp = (t) ? Py_True : Py_False;
        Py_INCREF(temp);
        return temp;
    } else static if(isIntegral!T) {
        static if(isUnsigned!T) {
            return PyLong_FromUnsignedLongLong(t);
        }else static if(isSigned!T) {
            return PyLong_FromLongLong(t);
        }
    } else static if (is(T : C_long)) {
        return PyInt_FromLong(t);
    } else static if (is(T : C_longlong)) {
        return PyLong_FromLongLong(t);
    } else static if (isFloatingPoint!T) {
        return PyFloat_FromDouble(t);
    } else static if( isTuple!T) {
        T.Types tuple;
        foreach(i, _t; T.Types) {
            tuple[i] = t[i];
        }
        return PyTuple_FromItems(tuple);
    } else static if (is(Unqual!T _unused : Complex!F, F)) {
        return PyComplex_FromDoubles(t.re, t.im);
    } else static if(is(T == std.bigint.BigInt)) {
        import std.string: format = xformat;
        string num_str = format("%s\0",t);
        return PyLong_FromString(num_str.dup.ptr, null, 10);
    } else static if (is(T : string)) {
        return PyString_FromString((t ~ "\0").ptr);
    } else static if (is(T : wstring)) {
        return PyUnicode_FromWideChar(t, t.length);
    // Converts any array (static or dynamic) to a Python list
    } else static if (isArray!(T)) {
        PyObject* lst = PyList_New(t.length);
        PyObject* temp;
        if (lst is null) return null;
        for(int i=0; i<t.length; ++i) {
            temp = _py(t[i]);
            if (temp is null) {
                Py_DECREF(lst);
                return null;
            }
            // Steals the reference to temp
            PyList_SET_ITEM(lst, i, temp);
        }
        return lst;
    // Converts any associative array to a Python dict
    } else static if (isAssociativeArray!(T)) {
        PyObject* dict = PyDict_New();
        PyObject* ktemp, vtemp;
        int result;
        if (dict is null) return null;
        foreach(k, v; t) {
            ktemp = _py(k);
            vtemp = _py(v);
            if (ktemp is null || vtemp is null) {
                if (ktemp !is null) Py_DECREF(ktemp);
                if (vtemp !is null) Py_DECREF(vtemp);
                Py_DECREF(dict);
                return null;
            }
            result = PyDict_SetItem(dict, ktemp, vtemp);
            Py_DECREF(ktemp);
            Py_DECREF(vtemp);
            if (result == -1) {
                Py_DECREF(dict);
                return null;
            }
        }
        return dict;
    } else static if (is(T == delegate) || is(T == function)) {
        PydWrappedFunc_Ready!(T)();
        return WrapPyObject_FromObject(t);
    } else static if (is(T : PydObject)) {
        return Py_INCREF(t.ptr());
    // The function expects to be passed a borrowed reference and return an
    // owned reference. Thus, if passed a PyObject*, this will increment the
    // reference count.
    } else static if (is(T : PyObject*)) {
        Py_INCREF(t);
        return t;
    // Convert wrapped type to a PyObject*
    } else static if (is(T == class)) {
        // But only if it actually is a wrapped type. :-)
        PyTypeObject** type = t.classinfo in wrapped_classes;
        if (type) {
            return WrapPyObject_FromTypeAndObject(*type, t);
        }
        // If it's not a wrapped type, fall through to the exception.
    // If converting a struct by value, create a copy and wrap that
    } else static if (is(T == struct)) {
        if (is_wrapped!(T*)) {
            T* temp = new T;
            *temp = t;
            return WrapPyObject_FromObject(temp);
        }
    // If converting a struct by reference, wrap the thing directly
    } else static if (is(typeof(*t) == struct)) {
        if (is_wrapped!(T)) {
            if (t is null) {
                Py_INCREF(Py_None);
                return Py_None;
            }
            return WrapPyObject_FromObject(t);
        }
    }
    // No conversion found, check runtime registry
    if (to_converter_registry!(T).dg) {
        return to_converter_registry!(T).dg(t);
    }
    PyErr_SetString(PyExc_RuntimeError, ("D conversion function _py failed with type " ~ typeid(T).toString()).ptr);
    return null;
}

/**
 * Helper function for creating a PyTuple from a series of D items.
 */
PyObject* PyTuple_FromItems(T ...)(T t) {
    PyObject* tuple = PyTuple_New(t.length);
    PyObject* temp;
    if (tuple is null) return null;
    foreach(i, arg; t) {
        temp = _py(arg);
        if (temp is null) {
            Py_DECREF(tuple);
            return null;
        }
        PyTuple_SetItem(tuple, i, temp);
    }
    return tuple;
}

/**
 * Constructs an object based on the type of the argument passed in.
 *
 * For example, calling py(10) would return a PydObject holding the value 10.
 *
 * Calling this with a PydObject will return back a reference to the very same
 * PydObject.
 */
PydObject py(T) (T t) {
    static if(is(T : PydObject)) {
        return t;
    } else {
        return new PydObject(_py(t));
    }
}

/**
 * An exception class used by d_type.
 */
class PydConversionException : Exception {
    this(string msg) { super(msg); }
}

/**
 * This converts a PyObject* to a D type. The template argument is the type to
 * convert to. The function argument is the PyObject* to convert. For instance:
 *
 *$(D_CODE PyObject* i = PyInt_FromLong(20);
 *int n = _d_type!(int)(i);
 *assert(n == 20);)
 *
 * This throws a PydConversionException if the PyObject can't be converted to
 * the given D type.
 */
T d_type(T) (PyObject* o) {
    // This ordering is somewhat important. The checks for Tuple and Complex
    // must be before the check for general structs.

    static if (is(PyObject* : T)) {
        return o;
    } else static if (is(PydObject : T)) {
        return new PydObject(borrowed(o));
    } else static if (is(T == void)) {
        if (o != Py_None) could_not_convert!(T)(o);
        return;
    } else static if (isTuple!T) {
        T.Types tuple;
        if(!PyTuple_Check(o)) could_not_convert!T(o);
        auto len = PyTuple_Size(o);
        if(len != T.Types.length) could_not_convert!T(o);
        foreach(i,_t; T.Types) {
            auto obj =  Py_XINCREF(PyTuple_GetItem(o, i));
            tuple[i] = d_type!_t(obj);
            Py_DECREF(obj);
        }
        return T(tuple);
    } else static if (is(Unqual!T _unused : Complex!F, F)) {
        double real_ = PyComplex_RealAsDouble(o);
        handle_exception();
        double imag = PyComplex_ImagAsDouble(o);
        handle_exception();
        return complex!(F,F)(real_, imag);
    } else static if(is(Unqual!T == std.bigint.BigInt)) {
        if (!PyNumber_Check(o)) could_not_convert!(T)(o);
        string num_str = d_type!string(o);
        if(num_str.endsWith("L")) num_str = num_str[0..$-1];
        return BigInt(num_str);
    } else static if(is(Unqual!T _unused : PydInputRange!E, E)) {
        return cast(T) PydInputRange!E(borrowed(o));
    } else static if (is(T == class)) {
        // We can only convert to a class if it has been wrapped, and of course
        // we can only convert the object if it is the wrapped type.
        if (
            is_wrapped!(T) &&
            PyObject_IsInstance(o, cast(PyObject*)&wrapped_class_type!(T)) &&
            cast(T)((cast(wrapped_class_object!(Object)*)o).d_obj) !is null
        ) {
            return WrapPyObject_AsObject!(T)(o);
        }
        // Otherwise, throw up an exception.
        //could_not_convert!(T)(o);
    } else static if (is(T == struct)) { // struct by value
        if (is_wrapped!(T*) && PyObject_TypeCheck(o, &wrapped_class_type!(T*))) { 
            return *WrapPyObject_AsObject!(T*)(o);
        }// else could_not_convert!(T)(o);
    } else static if (is(typeof(*(T.init)) == struct)) { // pointer to struct   
        if (is_wrapped!(T) && PyObject_TypeCheck(o, &wrapped_class_type!(T))) {
            return WrapPyObject_AsObject!(T)(o);
        }// else could_not_convert!(T)(o);
    } else static if (is(T == delegate)) {
        // Get the original wrapped delegate out if this is a wrapped delegate
        if (is_wrapped!(T) && PyObject_TypeCheck(o, &wrapped_class_type!(T))) {
            return WrapPyObject_AsObject!(T)(o);
        // Otherwise, wrap the PyCallable with a delegate
        } else if (PyCallable_Check(o)) {
            return PydCallable_AsDelegate!(T)(o);
        }// else could_not_convert!(T)(o);
    } else static if (is(T == function)) {
        // We can only make it a function pointer if we originally wrapped a
        // function pointer.
        if (is_wrapped!(T) && PyObject_TypeCheck(o, &wrapped_class_type!(T))) {
            return WrapPyObject_AsObject!(T)(o);
        }// else could_not_convert!(T)(o);
    /+
    } else static if (is(wchar[] : T)) {
        wchar[] temp;
        temp.length = PyUnicode_GetSize(o);
        PyUnicode_AsWideChar(cast(PyUnicodeObject*)o, temp, temp.length);
        return temp;
    +/
    } else static if (is(string : T) || is(char[] : T)) {
        const(char)* result;
        PyObject* repr;
        // If it's a string, convert it
        if (PyString_Check(o) || PyUnicode_Check(o)) {
            result = PyString_AsString(o);
        // If it's something else, convert its repr
        } else {
            repr = PyObject_Repr(o);
            if (repr is null) handle_exception();
            result = PyString_AsString(repr);
            Py_DECREF(repr);
        }
        if (result is null) handle_exception();
        static if (is(string : T)) {
            return to!string(result);
        } else {
            return to!string(result).dup;
        }
    } else static if (isArray!T) {
        alias Unqual!(ElementType!T) E;
        /*
        version(Python_2_6_Or_Later) {
            if(PyObject_CheckBuffer(o)) {
                assert(0, "todo: support new buffer interface");
            }
        }
        */
        if(o.ob_type is array_array_Type) {
            // array.array's data can be got with a single memcopy.
            arrayobject* arr_o = cast(arrayobject*) o;
            enforce(arr_o.ob_descr, "array.ob_descr null!");
            char typecode = cast(char) arr_o.ob_descr.typecode;
            switch(typecode) {
                case 'b','h','i','l':
                    if(!isSigned!E) 
                        could_not_convert!T(o,
                                format("typecode '%c' requires signed integer"
                                    " type, not '%s'", typecode, E.stringof));
                    break;
                case 'B','H','I','L':
                    if(!isUnsigned!E) 
                        could_not_convert!T(o,
                                format("typecode '%c' requires unsigned integer"
                                    " type, not '%s'",typecode, E.stringof));
                    break;
                case 'f','d':
                    if(!isFloatingPoint!E) 
                        could_not_convert!T(o,
                                format("typecode '%c' requires float, not '%s'",
                                    typecode, E.stringof));
                    break;
                case 'c','u': 
                    break;
                default:
                    could_not_convert!T(o, 
                            format("unknown typecode '%c'", typecode));
            }
            
            int itemsize = arr_o.ob_descr.itemsize;
            if(itemsize != E.sizeof) 
                could_not_convert!T(o, format("item size mismatch: %s vs %s", 
                            itemsize, E.sizeof));
            Py_ssize_t count = arr_o.ob_size; 
            if(count < 0) 
                could_not_convert!T(o, format("nonsensical array length: %s", 
                            count));
            static if(isDynamicArray!T) {
                E[] array = new E[](count);
            }else static if(isStaticArray!T){
                if(count != T.length) could_not_convert!T(o, format("length mismatch: %s vs %s", count, T.length));
                E[T.length] array;
            }
            // copy data, don't take slice
            array[] = cast(E[]) arr_o.ob_item[0 .. count*itemsize];
            return cast(T) array;
        }else {
            PyObject* iter = PyObject_GetIter(o);
            if (iter is null) {
                PyErr_Clear();
                could_not_convert!(T)(o);
            }
            scope(exit) Py_DECREF(iter);
            Py_ssize_t len = PyObject_Length(o);
            if (len == -1) {
                PyErr_Clear();
                could_not_convert!(T)(o);
            }
            static if(isDynamicArray!T) {
                E[] array = new E[](len);
            }else static if(isStaticArray!T){
                if(len != T.length) could_not_convert!T(o, format("length mismatch: %s vs %s", len, T.length));
                E[T.length] array;
            }
            int i = 0;
            PyObject* item = PyIter_Next(iter);
            while (item) {
                try {
                    array[i] = d_type!(E)(item);
                } catch(PydConversionException e) {
                    Py_DECREF(item);
                    // We re-throw the original conversion exception, rather than
                    // complaining about being unable to convert to an array. The
                    // partially constructed array is left to the GC.
                    throw e;
                }
                ++i;
                Py_DECREF(item);
                item = PyIter_Next(iter);
            }
            return cast(T) array;
        }
    } else static if (isFloatingPoint!T) {
        double res = PyFloat_AsDouble(o);
        handle_exception();
        return cast(T) res;
    } else static if(isIntegral!T) {
        if(PyInt_Check(o)) {
            C_long res = PyInt_AsLong(o);
            handle_exception();
            static if(isUnsigned!T) {
                if(res < 0) could_not_convert!T(o, format("%s out of bounds [%s, %s]", res, 0, T.max));
                if(T.max < res) could_not_convert!T(o,format("%s out of bounds [%s, %s]", res, 0, T.max));
                return cast(T) res;
            }else static if(isSigned!T) {
                if(T.min > res) could_not_convert!T(o, format("%s out of bounds [%s, %s]", res, T.min, T.max)); 
                if(T.max < res) could_not_convert!T(o, format("%s out of bounds [%s, %s]", res, T.min, T.max)); 
                return cast(T) res;
            }
        }else if(PyLong_Check(o)) {
            static if(isUnsigned!T) {
                static assert(T.sizeof <= C_ulonglong.sizeof);
                C_ulonglong res = PyLong_AsUnsignedLongLong(o);
                handle_exception();
                // no overflow from python to C_ulonglong,
                // overflow from C_ulonglong to T?
                if(T.max < res) could_not_convert!T(o); 
                return cast(T) res;
            }else static if(isSigned!T) {
                static assert(T.sizeof <= C_longlong.sizeof);
                C_longlong res = PyLong_AsLongLong(o);
                handle_exception();
                // no overflow from python to C_longlong,
                // overflow from C_longlong to T?
                if(T.min > res) could_not_convert!T(o); 
                if(T.max < res) could_not_convert!T(o); 
                return cast(T) res;
            }
        }else could_not_convert!T(o);
    } else static if (isBoolean!T) {
        if (!PyNumber_Check(o)) could_not_convert!(T)(o);
        int res = PyObject_IsTrue(o);
        handle_exception();
        return res == 1;
    }/+ else {
        could_not_convert!(T)(o);
    }+/
    if (from_converter_registry!(T).dg) {
        return from_converter_registry!(T).dg(o);
    }
    could_not_convert!(T)(o);
    assert(0);
}

@property PyTypeObject* array_array_Type() {
    static PyTypeObject* m_type;
    if(!m_type) {
        PyObject* array = PyImport_ImportModule("array");
        scope(exit) Py_XDECREF(array);
        m_type = cast(PyTypeObject*) PyObject_GetAttrString(array, "array");
    }
    return m_type;
}

alias d_type!(Object) d_type_Object;

private
void could_not_convert(T) (PyObject* o, string reason = "") {
    // Pull out the name of the type of this Python object, and the
    // name of the D type.
    string py_typename, d_typename;
    PyObject* py_type, py_type_str;
    py_type = PyObject_Type(o);
    if (py_type is null) {
        py_typename = "<unknown>";
    } else {
        py_type_str = PyObject_GetAttrString(py_type, cast(const(char)*) "__name__".ptr);
        Py_DECREF(py_type);
        if (py_type_str is null) {
            py_typename = "<unknown>";
        } else {
            py_typename = to!string(PyString_AsString(py_type_str));
            Py_DECREF(py_type_str);
        }
    }
    d_typename = typeid(T).toString();
    string because;
    if(reason != "") because = format(" because: %s", reason);
    throw new PydConversionException(
            format("Couldn't convert Python type '%s' to D type '%s'%s",
                py_typename,
                d_typename,
                because)
    );
}
