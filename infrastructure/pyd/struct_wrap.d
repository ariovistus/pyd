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
module pyd.struct_wrap;

import python;

import pyd.class_wrap;
import pyd.exception;
version(Pyd_with_StackThreads) {
    import pyd.iteration;
}
import pyd.make_object;
import pyd.lib_abstract :
    symbolnameof
;

//import std.stdio;
//import std.string;
//import meta.Nameof;

// With the exception of the T passed to wrapped_struct, it is intended that
// all of these templates accept a pointer-to-struct type as a template
// parameter, rather than the struct type itself.

template wrapped_member(T, M, size_t offset) {
    alias wrapped_class_type!(T) type;
    alias wrapped_class_object!(T) obj;
    //alias typeof(member) M;
    extern(C)
    PyObject* get(PyObject* self, void* closure) {
        return exception_catcher(delegate PyObject*() {
            T t = (cast(obj*)self).d_obj;
            M* m = cast(M*)(cast(void*)t + offset);
            return _py(*m);
        });
    }

    extern(C)
    int set(PyObject* self, PyObject* value, void* closure) {
        return exception_catcher(delegate int() {
            T t = (cast(obj*)self).d_obj;
            M* m = cast(M*)(cast(void*)(t) + offset);
            *m = d_type!(M)(value);
            return 0;
        });
    }
}

struct wrapped_struct(T, char[] structname = symbolnameof!(T)) {
    pragma(msg, "wrapped_struct: " ~ structname);
    static const char[] _name = structname;
    alias T* wrapped_type;

    static void member(M, size_t offset, char[] name) (char[] docstring="") {
        pragma(msg, "struct.member: " ~ name);
        static PyGetSetDef empty = {null, null, null, null, null};
        alias wrapped_prop_list!(T*) list;
        list[length-1].name = (name ~ "\0").ptr;
        list[length-1].get = &wrapped_member!(T*, M, offset).get;
        list[length-1].set = &wrapped_member!(T*, M, offset).set;
        list[length-1].doc = (docstring ~ "\0").ptr;
        list[length-1].closure = null;
        list ~= empty;
        wrapped_class_type!(T*).tp_getset = list.ptr;
    }

    alias wrapped_class!(T*, structname).def def;
    alias wrapped_class!(T*, structname).static_def static_def;
    alias wrapped_class!(T*, structname).prop prop;

    version(Pyd_with_StackThreads) {

    static void iter(iter_t) () {
        PydStackContext_Ready();
        wrapped_class_type!(T*).tp_iter = &wrapped_iter!(T*, T.opApply, int function(iter_t)).iter;
    }

    alias wrapped_class!(T*, structname).alt_iter alt_iter;

    } /*Pyd_with_StackThreads*/
}

alias pyd.class_wrap.finalize_class finalize_struct;

/+
void finalize_struct(SCT) (SCT sct, char[] modulename="") {
    alias SCT.wrapped_type T;
    alias wrapped_class_type!(T) type;
    const char[] name = SCT._name;
    pragma(msg, "finalize_struct: " ~ name);

    assert(Pyd_Module_p(modulename) !is null, "Must initialize module before wrapping structs.");
    char[] module_name = toString(PyModule_GetName(Pyd_Module_p(modulename)));
    // Fill in missing values
    type.ob_type      = PyType_Type_p();
    type.tp_basicsize = (wrapped_class_object!(T)).sizeof;
    type.tp_doc       = name ~ " objects" ~ "\0";
    type.tp_flags     = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
    //type.tp_repr      = &wrapped_repr!(T).repr;
    type.tp_methods   = wrapped_method_list!(T);
    type.tp_name      = module_name ~ "." ~ name ~ "\0";

}
+/
