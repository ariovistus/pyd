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
  Contains utilities for safely wrapping python exceptions in D and vice versa.
  */
module pyd.exception;

import std.conv;
import std.string: format;
import std.string;
import deimos.python.Python;
import std.traits : fullyQualifiedName;

/**
 * This function first checks if a Python exception is set, and then (if one
 * is) pulls it out, stuffs it in a PythonException, and throws that exception.
 *
 * If this exception is never caught, it will be handled by exception_catcher
 * (below) and passed right back into Python as though nothing happened.
 */
void handle_exception(string file = __FILE__, size_t line = __LINE__) {
    PyObject* type, value, traceback;
    if (PyErr_Occurred() !is null) {
        PyErr_Fetch(&type, &value, &traceback);
        PyErr_NormalizeException(&type, &value, &traceback);
        throw new PythonException(type, value, traceback,file,line);
    }
}

// Used internally.
T error_code(T) () {
    static if (is(T == PyObject*)) {
        return null;
    } else static if (is(T == int)) {
        return -1;
    } else static if (is(T == Py_ssize_t)) {
        return -1;
    } else static if (is(T == void)) {
        return;
    } else static assert(false, "exception_catcher cannot handle return type " ~ fullyQualifiedName!T);
}

/**
 * It is intended that any functions that interface directly with Python which
 * have the possibility of a D exception being raised wrap their contents in a
 * call to this function, e.g.:
 *
 *$(D_CODE extern (C)
 *PyObject* some_func(PyObject* self) {
 *    return _exception_catcher({
 *        // ...
 *    });
 *})
 */
T exception_catcher(T) (T delegate() dg) {
    try {
        return dg();
    }
    // A Python exception was raised and duly re-thrown as a D exception.
    // It should now be re-raised as a Python exception.
    catch (PythonException e) {
        PyErr_Restore(e.type(), e.value(), e.traceback());
        return error_code!(T)();
    }
    // A D exception was raised and should be translated into a meaningful
    // Python exception.
    catch (Exception e) {
        PyErr_SetString(PyExc_RuntimeError, ("D Exception:\n" ~ e.toString() ~ "\0").ptr);
        return error_code!(T)();
    }
    // Some other D object was thrown. Deal with it.
    catch (Throwable o) {
        PyErr_SetString(PyExc_RuntimeError, ("thrown D Object: " ~ o.classinfo.name ~ ": " ~ o.toString() ~ "\0").ptr);
        return error_code!(T)();
    }
}

// waaa! std.string.format (and likely Object.toString) do gc allocations!
T exception_catcher_nogc(T) (T delegate() dg) {
    try {
        return dg();
    }
    // A Python exception was raised and duly re-thrown as a D exception.
    // It should now be re-raised as a Python exception.
    catch (PythonException e) {
        PyErr_Restore(e.type(), e.value(), e.traceback());
        return error_code!(T)();
    }
    // A D exception was raised and should be translated into a meaningful
    // Python exception.
    catch (Throwable e) {
        //auto clz1 = e.classinfo;
        //const(char)* clz = e.classinfo.name.ptr;
        //const(char)* msg = e.msg.ptr;
        //const(char)* file = e.file.ptr;
        PyObject* p = PyBytes_FromFormat("some thrown D object:\0",
                /*clz, msg, file, e.line*/);
        PyErr_SetObject(PyExc_RuntimeError, p);
        Py_DECREF(p); // PyErr_SetObject has ownership of it now
        return error_code!(T)();
    }
}

alias exception_catcher!(PyObject*) exception_catcher_PyObjectPtr;
alias exception_catcher!(int) exception_catcher_int;
alias exception_catcher!(void) exception_catcher_void;

string printSyntaxError(PyObject* type, PyObject* value, PyObject* traceback) {
    if(value is null) return "";
    string text;
    auto ptext = PyObject_GetAttrString(value, "text");
    if(ptext) {
        version(Python_3_0_Or_Later) {
            ptext = PyUnicode_AsUTF8String(ptext);
        }
        auto p2text = PyBytes_AsString(ptext);
        if(p2text) text = strip(to!string(p2text));
    }
    C_long offset;
    auto poffset = PyObject_GetAttrString(value, "offset");
    if(poffset) {
        offset = PyLong_AsLong(poffset);
    }
    auto valtype = to!string(value.ob_type.tp_name);

    string message;
    auto pmsg = PyObject_GetAttrString(value, "msg");
    if(pmsg) {
        version(Python_3_0_Or_Later) {
            pmsg = PyUnicode_AsUTF8String(pmsg);
        }
        auto cmsg = PyBytes_AsString(pmsg);
        if(cmsg) message = to!string(cmsg);
    }
    string space = "";
    foreach(i; 0 .. offset-1) space ~= " ";
    return format(q"{
    %s
    %s^
%s: %s}", text, space,valtype, message);
}

string printGenericError(PyObject* type, PyObject* value, PyObject* traceback) {
    if(value is null) return "";
    auto valtype = to!string(value.ob_type.tp_name);

    string message;
    version(Python_3_0_Or_Later) {
        PyObject* uni = PyObject_Str(value);
    }else{
        PyObject* uni = PyObject_Unicode(value);
    }
    if(!uni) {
        PyErr_Clear();
        return "";
    }
    PyObject* str = PyUnicode_AsUTF8String(uni);
    if(!str) {
        PyErr_Clear();
        return "";
    }
    auto cmsg = PyBytes_AsString(str);
    if(cmsg) message = to!string(cmsg);
    return format(q"{
%s: %s}", valtype, message);
}

/**
 * This simple exception class holds a Python exception.
 */
class PythonException : Exception {
protected:
    PyObject* m_type, m_value, m_trace;
public:
    this(PyObject* type, PyObject* value, PyObject* traceback, string file = __FILE__, size_t line = __LINE__) {
        if(PyObject_IsInstance(value, cast(PyObject*)PyExc_SyntaxError)) {
            super(printSyntaxError(type, value, traceback), file, line);
        }else{
            super(printGenericError(type, value, traceback), file, line);
        }
        m_type = type;
        m_value = value;
        m_trace = traceback;
    }

    ~this() {
        if (m_type) Py_DECREF(m_type);
        if (m_value) Py_DECREF(m_value);
        if (m_trace) Py_DECREF(m_trace);
    }

    PyObject* type() {
        if (m_type) Py_INCREF(m_type);
        return m_type;
    }
    PyObject* value() {
        if (m_value) Py_INCREF(m_value);
        return m_value;
    }
    PyObject* traceback() {
        if (m_trace) Py_INCREF(m_trace);
        return m_trace;
    }

    @property py_message() {
        string message;
        PyObject* pmsg;
        if(m_value) {
            if(PyObject_IsInstance(m_value, cast(PyObject*)PyExc_SyntaxError)) {
                pmsg = PyObject_GetAttrString(m_value, "msg");
            }else{
                // todo: test this on other versions..
                version(Python_3_2_Or_Later) {
                    pmsg = PyObject_GetAttrString(m_value, "args");
                    if(pmsg != null && PyTuple_Check(pmsg) &&
                            PyTuple_Size(pmsg) >= 1) {
                        pmsg = cast(PyObject*) PyTuple_GetItem(pmsg, 0);
                    }

                }else{
                    pmsg = PyObject_GetAttrString(m_value, "message");
                }
            }
            if(pmsg) {
                import pyd.make_object;
                message = python_to_d!string(pmsg);
            }
        }

        return message;
    }

    @property py_offset() {
        C_long offset = -1;
        if(m_value) {
            auto poffset = PyObject_GetAttrString(m_value, "offset");
            if(poffset) {
                offset = PyLong_AsLong(poffset);
            }
        }
        return offset;
    }
}

