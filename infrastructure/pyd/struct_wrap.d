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

/**
  Contains utilities for wrapping D structs.
  */
module pyd.struct_wrap;

import std.traits;
import std.typetuple;
import deimos.python.Python;

import util.typeinfo;
import pyd.references;
import pyd.def;
import pyd.class_wrap;
import pyd.exception;
import pyd.make_object;

// It is intended that all of these templates accept a pointer-to-struct type
// as a template parameter, rather than the struct type itself.

template wrapped_member(T, string name, alias mode, PropertyParts...) {
    alias PydTypeObject!(T) type;
    alias wrapped_class_object!(T) obj;
    static if(PropertyParts.length != 0) {
        alias PropertyParts[0] ppart0;
        alias ppart0.Type M;
        // const setters make no sense. getters though..
        static if(ppart0.isgproperty) {
            alias ApplyConstness2!(T,constness!(FunctionTypeOf!(ppart0.GetterFn)))
                GT;
        }
    }else {
        alias T GT;
        mixin("alias typeof(T."~name~") M;");
    }

    static if(mode.has_get) {
        static if(PropertyParts.length != 0) {
        }
        extern(C)
            PyObject* get(PyObject* self, void* closure) {
            return exception_catcher(delegate PyObject*() {
                GT t = get_d_reference!GT(self);
                mixin("return d_to_python(t."~name~");");
            });
        }
    }

    static if(mode.has_set) {
        extern(C)
        int set(PyObject* self, PyObject* value, void* closure) {
            return exception_catcher(delegate int() {
                T t = get_d_reference!T(self);
                mixin("t."~name~" = python_to_d!(M)(value);");
                return 0;
            });
        }
    }
}

/**
Wrap a member variable of a class or struct.

Params:
name = The name of the member to wrap
Options = Optional parameters. Takes Docstring!(docstring), PyName!(pyname),
and Mode!(mode)
pyname = The name of the member as it will appear in Python. Defaults to name
mode = specifies whether this member is readable, writable. possible values
are "r", "w", "rw". Defaults to "rw".
docstring = The function's docstring. Defaults to "".
*/
struct Member(string name, Options...) {
    enum template_name = "Member";
    
    alias Args!("","", name, "rw",Options) args;
    enum realname = name;
    alias parts = TypeTuple!();
    enum mode = PropertyMode(true, true);
}

/// Wrap a struct.
alias wrap_class wrap_struct;

