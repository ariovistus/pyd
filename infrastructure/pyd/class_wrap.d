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
module pyd.class_wrap;

import python;

import std.algorithm: countUntil;
import std.traits;
import std.exception: enforce;
import std.metastrings;
import std.typetuple;
import std.string: format;
import std.typecons: Tuple;
import util.typelist: Filter, Pred;
import util.multi_index;
import util.replace: Replace;
import pyd.ctor_wrap;
import pyd.def;
import pyd.dg_convert;
import pyd.exception;
import pyd.func_wrap;
import pyd.make_object;
import pyd.make_wrapper;
import pyd.op_wrap;
import pyd.lib_abstract :
    symbolnameof,
    prettytypeof,
    toString,
    ParameterTypeTuple,
    ReturnType,
    minArgs,
    objToStr ;

version(Pyd_with_StackThreads) static assert(0, "sorry - stackthreads are gone");

PyTypeObject*[ClassInfo] wrapped_classes;
template shim_class(T) {
    PyTypeObject* shim_class;
}

// This is split out in case I ever want to make a subtype of a wrapped class.
template PydWrapObject_HEAD(T) {
    mixin PyObject_HEAD;
    T d_obj;
}

/// The class object, a subtype of PyObject
template wrapped_class_object(T) {
    extern(C)
    struct wrapped_class_object {
        mixin PydWrapObject_HEAD!(T);
    }
}

///
template wrapped_class_type(T) {
/// The type object, an instance of PyType_Type
    static PyTypeObject wrapped_class_type = {
        1,                            /*ob_refcnt*/
        null,                         /*ob_type*/
        0,                            /*ob_size*/
        null,                         /*tp_name*/
        0,                            /*tp_basicsize*/
        0,                            /*tp_itemsize*/
        &wrapped_methods!(T).wrapped_dealloc, /*tp_dealloc*/
        null,                         /*tp_print*/
        null,                         /*tp_getattr*/
        null,                         /*tp_setattr*/
        null,                         /*tp_compare*/
        null,                         /*tp_repr*/
        null,                         /*tp_as_number*/
        null,                         /*tp_as_sequence*/
        null,                         /*tp_as_mapping*/
        null,                         /*tp_hash */
        null,                         /*tp_call*/
        null,                         /*tp_str*/
        null,                         /*tp_getattro*/
        null,                         /*tp_setattro*/
        null,                         /*tp_as_buffer*/
        0,                            /*tp_flags*/
        null,                         /*tp_doc*/
        null,                         /*tp_traverse*/
        null,                         /*tp_clear*/
        null,                         /*tp_richcompare*/
        0,                            /*tp_weaklistoffset*/
        null,                         /*tp_iter*/
        null,                         /*tp_iternext*/
        null,                         /*tp_methods*/
        null,                         /*tp_members*/
        null,                         /*tp_getset*/
        null,                         /*tp_base*/
        null,                         /*tp_dict*/
        null,                         /*tp_descr_get*/
        null,                         /*tp_descr_set*/
        0,                            /*tp_dictoffset*/
        null,                         /*tp_init*/
        null,                         /*tp_alloc*/
        &wrapped_methods!(T).wrapped_new, /*tp_new*/
        null,                         /*tp_free*/
        null,                         /*tp_is_gc*/
        null,                         /*tp_bases*/
        null,                         /*tp_mro*/
        null,                         /*tp_cache*/
        null,                         /*tp_subclasses*/
        null,                         /*tp_weaklist*/
        null,                         /*tp_del*/
    };
}

// A mapping of all class references that are being held by Python.
alias Tuple!(void*,"d",PyObject*,"py") D2Py;
alias MultiIndexContainer!(D2Py, IndexedBy!(HashedUnique!("a.d")), 
        MallocAllocator, MutableView) WrappedObjectMap;

WrappedObjectMap _wrapped_gc_objects = null;

// would initialize in static this, but static this apparently isn't run
// in shared libs
@property wrapped_gc_objects() {
    if(!_wrapped_gc_objects) _wrapped_gc_objects = new WrappedObjectMap();
    return _wrapped_gc_objects;
}

template Dt2Py(dg_t) {
    alias Tuple!(dg_t,"d",PyObject*,"py") Dt2Py;
}

// A mapping of all GC references that are being held by Python.
template wrapped_gc_references(dg_t) {
    alias MultiIndexContainer!(Dt2Py!dg_t, IndexedBy!(HashedUnique!("a.d")), 
            MallocAllocator, MutableView) WrappedReferenceMap;
    WrappedReferenceMap _wrapped_gc_references;

    @property wrapped_gc_references() {
        if(!_wrapped_gc_references) 
            _wrapped_gc_references = new WrappedReferenceMap();
        return _wrapped_gc_references;
    }
}

/**
 * A useful check for whether a given class has been wrapped. Mainly used by
 * the conversion functions (see make_object.d), but possibly useful elsewhere.
 */
template is_wrapped(T) {
    bool is_wrapped = false;
}

// The list of wrapped methods for this class.
template wrapped_method_list(T) {
    PyMethodDef[] wrapped_method_list = [
        { null, null, 0, null }
    ];
}

// The list of wrapped properties for this class.
template wrapped_prop_list(T) {
    static PyGetSetDef[] wrapped_prop_list = [
        { null, null, null, null, null }
    ];
}

//////////////////////
// STANDARD METHODS //
//////////////////////

//import std.stdio;

/// Various wrapped methods
template wrapped_methods(T) {
    alias wrapped_class_object!(T) wrap_object;
    /// The generic "__new__" method
    extern(C)
    PyObject* wrapped_new(PyTypeObject* type, PyObject* args, PyObject* kwds) {
        return exception_catcher(delegate PyObject*() {
            wrap_object* self;

            self = cast(wrap_object*)type.tp_alloc(type, 0);
            if (self !is null) {
                self.d_obj = null;
            }

            return cast(PyObject*)self;
        });
    }

    /// The generic dealloc method.
    extern(C)
    void wrapped_dealloc(PyObject* self) {
        // EMN: the *&%^^%! generic dealloc method is triggering a call to
        //  *&^%*%(! malloc for that delegate during a @(*$76*&! 
        //  garbage collection
        //  Solution: don't use a *&%%^^! delegate in a destructor!
        static struct StackDelegate{
            PyObject* x;
            void dg() {
                WrapPyObject_SetObj!(T)(x, cast(T)null);
                x.ob_type.tp_free(x);
            }
        }
        StackDelegate x;
        x.x = self;
        exception_catcher(&x.dg);
    }
}

template wrapped_repr(T, alias fn) {
    alias wrapped_class_object!(T) wrap_object;
    /// The default repr method calls the class's toString.
    extern(C)
    PyObject* repr(PyObject* self) {
        return exception_catcher(delegate PyObject*() {
            return method_wrap!(T, fn, string function()).func(self, null);
        });
    }
}

private template ID(A){ alias A ID; }
private struct CW(A...){ alias A C; }

template IsProperty(alias T) {
    enum bool IsProperty = 
        (functionAttributes!(T) & FunctionAttribute.property);
}

template IsGetter(alias T) {
    enum bool IsGetter = ParameterTypeTuple!T .length == 0 && 
        !is(ReturnType!T == void);
}

template IsSetter(RT) {
    template IsSetter(alias T) {
        enum bool IsSetter = ParameterTypeTuple!T .length == 1 && 
                is(ParameterTypeTuple!(T)[0] == RT);
    }
}

// This template gets an alias to a property and derives the types of the
// getter form and the setter form. It requires that the getter form return the
// same type that the setter form accepts.
struct property_parts(alias p, bool RO) {
    alias ID!(__traits(parent, p)) Parent;
    enum nom = __traits(identifier, p);
    alias TypeTuple!(__traits(getOverloads, Parent, nom)) Overloads;
    alias Filter!(IsGetter,Overloads) Getters;
    static assert(Getters.length != 0, Format!("can't find property %s.%s getter", Parent.stringof, nom));
    static assert(Getters.length == 1, 
            Format!("can't handle property overloads of %s.%s getter (types %s)", 
                Parent.stringof, nom, staticMap!(ReturnType,Getters).stringof));
    alias Getters[0] GetterFn;
    alias typeof(&GetterFn) getter_type;
    static assert(!IsProperty!(GetterFn), 
            Format!("%s.%s: can't handle d properties", Parent.stringof, nom));
    static if(!RO) {
        alias Filter!(IsSetter!(ReturnType!getter_type), Overloads) Setters;
        static assert(Setters.length != 0, Format!("can't find property %s.%s setter", Parent.stringof, nom));
        static assert(Setters.length == 1, 
                Format!("can't handle property overloads of %s.%s setter (return types %s)", 
                    Parent.stringof, nom, staticMap!(ReturnType,Getters).stringof));
        alias Setters[0] SetterFn;
        alias typeof(&SetterFn) setter_type;
    static assert(!IsProperty!(Setters[0]), 
            Format!("%s.%s: can't handle d properties", Parent.stringof, nom));
    }
}

///
template wrapped_get(T, Parts) {
    /// A generic wrapper around a "getter" property.
    extern(C)
    PyObject* func(PyObject* self, void* closure) {
        // method_wrap already catches exceptions
        return method_wrap!(T, Parts.GetterFn, Parts.getter_type).func(self, null);
    }
}

///
template wrapped_set(T, Parts) {
    /// A generic wrapper around a "setter" property.
    extern(C)
    int func(PyObject* self, PyObject* value, void* closure) {
        PyObject* temp_tuple = PyTuple_New(1);
        if (temp_tuple is null) return -1;
        scope(exit) Py_DECREF(temp_tuple);
        Py_INCREF(value);
        PyTuple_SetItem(temp_tuple, 0, value);
        PyObject* res = method_wrap!(T, Parts.SetterFn, Parts.setter_type).func(self, temp_tuple);
        // If we get something back, we need to DECREF it.
        if (res) Py_DECREF(res);
        // If we don't, propagate the exception
        else return -1;
        // Otherwise, all is well.
        return 0;
    }
}

//////////////////////////////
// CLASS WRAPPING INTERFACE //
//////////////////////////////

/+
/**
 * This struct wraps a D class. Its member functions are the primary way of
 * wrapping the specific parts of the class.
 */
struct wrapped_class(T, char[] classname = symbolnameof!(T)) {
    static if (is(T == class)) pragma(msg, "wrapped_class: " ~ classname);
    static const char[] _name = classname;
    static bool _private = false;
    alias T wrapped_type;
+/

//enum ParamType { Def, StaticDef, Property, Init, Parent, Hide, Iter, AltIter }
struct DoNothing {
    static void call(T) () {}
}
/**
Wraps a member function of the class.

Params:
fn = The member function to wrap.
name = The name of the function as it will appear in Python.
fn_t = The type of the function. It is only useful to specify this
       if more than one function has the same name as this one.
*/
struct Def(alias fn) {
    mixin _Def!(fn, symbolnameof!(fn), typeof(&fn), "");
}
struct Def(alias fn, string docstring) {
    mixin _Def!(fn, /*symbolnameof!(fn),*/ symbolnameof!(fn), typeof(&fn)/+, minArgs!(fn)+/, docstring);
}
struct Def(alias fn, string name, string docstring) {
    mixin _Def!(fn, /*symbolnameof!(fn),*/ name, typeof(&fn)/+, minArgs!(fn)+/, docstring);
}
struct Def(alias fn, string name, fn_t) {
    mixin _Def!(fn, /*symbolnameof!(fn),*/ name, fn_t/+, minArgs!(fn)+/, "");
}
struct Def(alias fn, fn_t) {
    mixin _Def!(fn, /*symbolnameof!(fn),*/ symbolnameof!(fn), fn_t/+, minArgs!(fn)+/, "");
}
struct Def(alias fn, fn_t, string docstring) {
    mixin _Def!(fn, /*symbolnameof!(fn),*/ symbolnameof!(fn), fn_t/+, minArgs!(fn)+/, docstring);
}
struct Def(alias fn, string name, fn_t, string docstring) {
    mixin _Def!(fn, /*symbolnameof!(fn),*/ name, fn_t/+, minArgs!(fn)+/, docstring);
}
/+
template Def(alias fn, string name, fn_t, uint MIN_ARGS=minArgs!(fn)/+, string docstring=""+/) {
    alias Def!(fn, /*symbolnameof!(fn),*/ name, fn_t, MIN_ARGS/+, docstring+/) Def;
}
+/
template _Def(alias fn, /*string _realname,*/ string name, fn_t/+, uint MIN_ARGS=minArgs!(fn)+/, string docstring) {
    //static const type = ParamType.Def;
    alias fn func;
    alias fn_t func_t;
    enum realname = symbolnameof!(fn);//_realname;
    enum funcname = name;
    enum min_args = minArgs!(fn);
    enum bool needs_shim = false;

    static void call(T) () {
        pragma(msg, "class.def: " ~ name);
        static PyMethodDef empty = { null, null, 0, null };
        alias wrapped_method_list!(T) list;
        list[$-1].ml_name = (name ~ "\0").ptr;
        list[$-1].ml_meth = &method_wrap!(T, fn, fn_t).func;
        list[$-1].ml_flags = METH_VARARGS;
        list[$-1].ml_doc = (docstring~"\0").ptr;
        list ~= empty;
        // It's possible that appending the empty item invalidated the
        // pointer in the type struct, so we renew it here.
        wrapped_class_type!(T).tp_methods = list.ptr;
    }
    template shim(uint i) {
        enum shim = Replace!(q{    
            alias Params[$i] __pyd_p$i;
            ReturnType!(__pyd_p$i.func_t) $realname(ParameterTypeTuple!(__pyd_p$i.func_t) t) {
                return __pyd_get_overload!("$realname", __pyd_p$i.func_t).func("$name", t);
            }
        }, "$i",i,"$realname",realname, "$name", name);
    }
}

/**
Wraps a static member function of the class. Identical to pyd.def.def
*/
struct StaticDef(alias fn) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ symbolnameof!(fn), typeof(&fn), minArgs!(fn), "");
}
struct StaticDef(alias fn, string docstring) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ symbolnameof!(fn), typeof(&fn), minArgs!(fn), docstring);
}
struct StaticDef(alias _fn, string name, string docstring) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ name, typeof(&fn), minArgs!(fn), docstring);
}
struct StaticDef(alias _fn, string name, fn_t, string docstring) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ name, fn_t, minArgs!(fn), docstring);
}
struct StaticDef(alias _fn, fn_t) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ symbolnameof!(fn), fn_t, minArgs!(fn), "");
}
struct StaticDef(alias _fn, fn_t, string docstring) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ symbolnameof!(fn), fn_t, minArgs!(fn), docstring);
}
struct StaticDef(alias _fn, string name, fn_t) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ name, fn_t, minArgs!(fn), "");
}
struct StaticDef(alias _fn, string name, fn_t, uint MIN_ARGS) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ name, fn_t, MIN_ARGS, "");
}
struct StaticDef(alias _fn, string name, fn_t, uint MIN_ARGS, string docstring) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ name, fn_t, MIN_ARGS, docstring);
}
mixin template _StaticDef(alias fn,/+ string _realname,+/ string name, fn_t, uint MIN_ARGS, string docstring) {
    //static const type = ParamType.StaticDef;
    alias fn func;
    alias fn_t func_t;
    enum funcname = name;
    enum min_args = MIN_ARGS;
    enum bool needs_shim = false;
    static void call(T) () {
        pragma(msg, "class.static_def: " ~ name);
        static PyMethodDef empty = { null, null, 0, null };
        alias wrapped_method_list!(T) list;
        list[$-1].ml_name = (name ~ "\0").ptr;
        list[$-1].ml_meth = &function_wrap!(fn, MIN_ARGS, fn_t).func;
        list[$-1].ml_flags = METH_VARARGS | METH_STATIC;
        list[$-1].ml_doc = (docstring~"\0").ptr;
        list ~= empty;
        wrapped_class_type!(T).tp_methods = list;
    }
    template shim(uint i) {
        enum shim = "";
    }
}

/**
Wraps a property of the class.

Params:
fn = The property to wrap.
name = The name of the property as it will appear in Python.
RO = Whether this is a read-only property.
*/
//template Property(alias fn, char[] name = symbolnameof!(fn), bool RO=false, char[] docstring = "") {
//    alias Property!(fn, symbolnameof!(fn), name, RO, docstring) Property;
//}
struct Property(alias fn) {
    mixin _Property!(fn, symbolnameof!(fn), symbolnameof!(fn), false, "");
}
struct Property(alias fn, string docstring) {
    mixin _Property!(fn, symbolnameof!(fn), symbolnameof!(fn), false, docstring);
}
struct Property(alias fn, string name, string docstring) {
    mixin _Property!(fn, symbolnameof!(fn), name, false, docstring);
}
struct Property(alias fn, string name, bool RO) {
    mixin _Property!(fn, symbolnameof!(fn), name, RO, "");
}
struct Property(alias fn, string name, bool RO, string docstring) {
    mixin _Property!(fn, symbolnameof!(fn), name, RO, docstring);
}
struct Property(alias fn, bool RO) {
    mixin _Property!(fn, symbolnameof!(fn), symbolnameof!(fn), RO, "");
}
struct Property(alias fn, bool RO, string docstring) {
    mixin _Property!(fn, symbolnameof!(fn), symbolnameof!(fn), RO, docstring);
}
template _Property(alias fn, string _realname, string name, bool RO, string docstring) {
    alias property_parts!(fn, RO) parts;
    alias parts.getter_type get_t;
    static if(!RO) {
        alias parts.setter_type set_t;
    }
    enum realname = _realname;
    enum funcname = name;
    enum bool readonly = RO;
    enum bool needs_shim = false;
    static void call(T) () {
        pragma(msg, "class.prop: " ~ name);
        static PyGetSetDef empty = { null, null, null, null, null };
        wrapped_prop_list!(T)[$-1].name = (name ~ "\0").dup.ptr;
        wrapped_prop_list!(T)[$-1].get =
            &wrapped_get!(T, parts).func;
        static if (!RO) {
            wrapped_prop_list!(T)[$-1].set =
                &wrapped_set!(T, parts).func;
        }
        wrapped_prop_list!(T)[$-1].doc = (docstring~"\0").dup.ptr;
        wrapped_prop_list!(T)[$-1].closure = null;
        wrapped_prop_list!(T) ~= empty;
        // It's possible that appending the empty item invalidated the
        // pointer in the type struct, so we renew it here.
        wrapped_class_type!(T).tp_getset =
            wrapped_prop_list!(T).ptr;
    }
    template shim_setter(uint i) {
        static if (RO) {
            enum shim_setter = "";
        } else {
            enum shim_setter = Replace!(q{
                ReturnType!(__pyd_p$i.set_t) $realname(ParameterTypeTuple!(__pyd_p$i.set_t) t) {
                    return __pyd_get_overload!("$realname", __pyd_p$i.set_t).func("$name", t);
                }
            }, "$i", i, "$realname",_realname, "$name", name);
        }
    }
    template shim(uint i) {
        enum shim = Replace!(q{
            alias Params[$i] __pyd_p$i;
            ReturnType!(__pyd_p$i.get_t) $realname() {
                return __pyd_get_overload!("$realname", __pyd_p$i.get_t).func("$name");
            }
            $shim_setter;
        }, "$i",i,"$realname",_realname, "$name", name, "$shim_setter",shim_setter!(i));
    }
}

/**
Wraps a method as the class's __repr__ in Python.
*/
struct Repr(alias fn) {
    enum bool needs_shim = false;
    static void call(T)() {
        alias wrapped_class_type!(T) type;
        type.tp_repr = &wrapped_repr!(T, fn).repr;
    }
    template shim(uint i) {
        enum shim = "";
    }
}

/**
Wraps the constructors of the class.

This template takes a series of specializations of the ctor template
(see ctor_wrap.d), each of which describes a different constructor
that the class supports. The default constructor need not be
specified, and will always be available if the class supports it.

Bugs:
This currently does not support having multiple constructors with
the same number of arguments.
*/
struct Init(C ...) {
    alias C ctors;
    enum bool needs_shim = true;
    template call(T, shim) {
        //mixin wrapped_ctors!(param.ctors) Ctors;
        static void call() {
            wrapped_class_type!(T).tp_init =
                //&Ctors.init_func;
                &wrapped_ctors!(shim, C).init_func;
        }
    }
    template shim_impl(uint i, uint c=0) {
        static if (c < ctors.length) {
            enum shim_impl = Replace!(q{
                this(ParameterTypeTuple!(__pyd_c$i[$c]) t) {
                    super(t);
                }
                $shim_impl;
            }, "$i",i,"$c",c,"$shim_impl",shim_impl!(i,c+1));
        } else {
            enum shim_impl = q{
                static if (is(typeof(new T))) {
                    this() { super(); }
                }
            };
        }
    }
    template shim(uint i) {
        enum shim = Replace!(q{
            alias Params[$i] __pyd_p$i;
            alias __pyd_p$i.ctors __pyd_c$i;
            $shim_impl;
        }, "$i", i, "$shim_impl", shim_impl!(i));
    }
}

enum binaryslots = [
    "+": "type.tp_as_number.nb_add", 
    "+=": "type.tp_as_number.nb_inplace_add", 
    "-": "type.tp_as_number.nb_subtract", 
    "-=": "type.tp_as_number.nb_inplace_subtract", 
    "*": "type.tp_as_number.nb_multiply",
    "*=": "type.tp_as_number.nb_inplace_multiply",
    "/": "type.tp_as_number.nb_divide",
    "/=": "type.tp_as_number.nb_inplace_divide",
    "%": "type.tp_as_number.nb_remainder",
    "%=": "type.tp_as_number.nb_inplace_remainder",
    "^^": "type.tp_as_number.nb_power",
    "^^=": "type.tp_as_number.nb_inplace_power",
    "<<": "type.tp_as_number.nb_lshift",
    "<<=": "type.tp_as_number.nb_inplace_lshift",
    ">>": "type.tp_as_number.nb_rshift",
    ">>=": "type.tp_as_number.nb_inplace_rshift",
    "&": "type.tp_as_number.nb_and",
    "&=": "type.tp_as_number.nb_inplace_and",
    "^": "type.tp_as_number.nb_xor",
    "^=": "type.tp_as_number.nb_inplace_xor",
    "|": "type.tp_as_number.nb_or",
    "|=": "type.tp_as_number.nb_inplace_or",
    "~": "type.tp_as_sequence.sq_concat",
    "~=": "type.tp_as_sequence.sq_inplace_concat",
    "in": "type.tp_as_sequence.sq_contains",
];

bool IsPyBinary(string op) {
    foreach(_op, slot; binaryslots) {
        if (op[$-1] != '=' && op == _op) return true;
    }
    return false;
}
bool IsPyAsg(string op0) {
    auto op = op0~"=";
    foreach(_op, slot; binaryslots) {
        if (op == _op) return true;
    }
    return false;
}

enum unaryslots = [
    "+": "type.tp_as_number.nb_positive",
    "-": "type.tp_as_number.nb_negative",
    "~": "type.tp_as_number.nb_invert",
];

bool IsPyUnary(string op) {
    foreach(_op, slot; unaryslots) {
        if(op == _op) return true;
    }
    return false;
}

// string mixin to initialize tp_as_number or tp_as_sequence or tp_as_mapping
// if necessary. Scope mixed in must have these variables:
//  slot: a value from binaryslots or unaryslots
//  type: a PyObjectType.
string autoInitializeMethods() {
    return q{
        static if(countUntil(slot, "tp_as_number") != -1) {
            if(type.tp_as_number is null) 
                type.tp_as_number = new PyNumberMethods;
        }else static if(countUntil(slot, "tp_as_sequence") != -1) {
            if(type.tp_as_sequence is null) 
                type.tp_as_sequence = new PySequenceMethods;
        }else static if(countUntil(slot, "tp_as_mapping") != -1) {
            if(type.tp_as_mapping is null) 
                type.tp_as_mapping = new PyMappingMethods;
        }
    };
}

private struct Guess{}

struct BinaryOperatorX(string _op, bool isR, rhs_t) {
    enum op = _op;
    enum isRight = isR;

    static if(isR) enum nom = "opBinaryRight";
    else enum nom = "opBinary";

    enum bool needs_shim = false;

    template Inner(C) {
        enum fn_str1 = "Alias!(C."~nom~"!(op))";
        enum fn_str2 = "Alias!(C."~nom~"!(op,rhs_t))";
        enum string OP = op;
        static if(!__traits(hasMember, C, nom)) {
            static assert(0, C.stringof ~ " has no "~(isR ?"reflected ":"")~
                    "binary operator overloads");
        }
        template Alias(alias fn) {
            alias fn Alias;
        }
        static if(is(typeof(mixin(fn_str1)) == function)) {
            alias ParameterTypeTuple!(typeof(mixin(fn_str1)))[0] RHS_T;
            alias ReturnType!(typeof(mixin(fn_str1))) RET_T;
            mixin("alias " ~ fn_str1 ~ " FN;");
            static if(!is(rhs_t == Guess))
                static assert(is(RHS_T == rhs_t), 
                        Format!("expected typeof(rhs) = %s, found %s", 
                            rhs.stringof, RHS_T.stringof));
        }else static if(is(rhs_t == Guess)) {
            static assert(false, 
                    Format!("Operator %s: Cannot determine type of rhs", op));
        } else static if(is(typeof(mixin(fn_str2)) == function)) {
            alias rhs_t RHS_T;
            alias ReturnType!(typeof(mixin(fn_str2))) RET_T;
            mixin("alias "~fn_str2~" FN;");
        } else static assert(false, "Cannot get operator overload");
    }

    static void call(T)() {
        // can't handle __op__ __rop__ pairs here
    }

    template shim(uint i) {
        // bah
        enum shim = "";
    }
}

template OpBinary(string op, rhs_t = Guess) if(IsPyBinary(op) && op != "in"){
    alias BinaryOperatorX!(op, false, rhs_t) OpBinary;
}

template OpBinaryRight(string op, lhs_t = Guess) if(IsPyBinary(op)) {
    alias BinaryOperatorX!(op, true, lhs_t) OpBinaryRight;
}

struct OpUnary(string _op) if(IsPyUnary(_op)) {
    enum op = _op;
    enum bool needs_shim = false;

    template Inner(C) {
        enum string OP = op;
        static if(!__traits(hasMember, C, "opUnary")) {
            static assert(0, C.stringof ~ " has no unary operator overloads");
        }
        static if(is(typeof(C.init.opUnary!(op)) == function)) {
            alias ReturnType!(C.opUnary!(op)) RET_T;
            alias C.opUnary!(op) FN;
        } else static assert(false, "Cannot get operator overload");
    }
    static void call(T)() {
        alias wrapped_class_type!T type;
        enum slot = unaryslots[op];
        mixin(autoInitializeMethods());
        mixin(slot ~ " = &opfunc_unary_wrap!(T, Inner!T .FN).func;");
    }
    template shim(uint i) {
        // bah
        enum shim = "";
    }
}

struct OpAssign(string _op, rhs_t = Guess) if(IsPyAsg(_op)) {
    enum op = _op~"=";

    enum bool needs_shim = false;

    template Inner(C) {
        enum string OP = op;
        static if(!__traits(hasMember, C, "opOpAssign")) {
            static assert(0, C.stringof ~ " has no operator assignment overloads");
        }
        static if(is(typeof(C.init.opOpAssign!(_op)) == function)) {
            alias ParameterTypeTuple!(typeof(C.opOpAssign!(_op)))[0] RHS_T;
            alias ReturnType!(typeof(C.opOpAssign!(_op))) RET_T;
            alias C.opOpAssign!(_op) FN;
            static if(!is(rhs_t == Guess))
                static assert(is(RHS_T == rhs_t), 
                        Format!("expected typeof(rhs) = %s, found %s", 
                            rhs.stringof, RHS_T.stringof));
        }else static if(is(rhs_t == Guess)) {
            static assert(false, "Cannot determine type of rhs");
        } else static if(is(typeof(C.opOpAssign!(_op,rhs_t)) == function)) {
            alias rhs_t RHS_T;
            alias ReturnType!(typeof(C.opOpAssign!(_op,rhs_t))) RET_T;
            alias C.opOpAssign!(_op,rhs_t) FN;
        } else static assert(false, "Cannot get operator assignment overload");
    }
    static void call(T)() {
        alias wrapped_class_type!T type;
        enum slot = binaryslots[op];
        mixin(autoInitializeMethods());
        alias CW!(TypeTuple!(OpAssign)) OpAsg;
        alias CW!(TypeTuple!()) Nop;
        static if(op == "^^=")
            mixin(slot ~ " = &powopasg_wrap!(T, Inner!T.FN).func;");
        else
            mixin(slot ~ " = &binopasg_wrap!(T, Inner!T.FN).func;");
    }

    template shim(uint i) {
        // bah
        enum shim = "";
    }
}

// struct types could probably take any parameter type
// class types must take Object
struct OpCompare(_rhs_t = Guess) {
    enum bool needs_shim = false;


    template Inner(C) {
        static if(is(_rhs_t == Guess) && is(C == class)) {
            alias Object rhs_t;
        }else {
            alias _rhs_t rhs_t;
        }
        static if(!__traits(hasMember, C, "opCmp")) {
            static assert(0, C.stringof ~ " has no comparison operator overloads");
        }
        static if(!is(typeof(C.init.opCmp) == function)) {
            static assert(0, Format!("why is %s.opCmp not a function?",C));
        }
        alias TypeTuple!(__traits(getOverloads, C, "opCmp")) Overloads;
        static if(is(rhs_t == Guess) && Overloads.length > 1) {
            static assert(0, Format!("Cannot choose between %s", Overloads));
        }else static if(Overloads.length == 1) {
            static if(!is(rhs_t == Guess) &&
                !is(ParameterTypeTuple!(Overloads[0])[0] == rhs_t)) {
                static assert(0, Format!("%s.opCmp: expected param %s, got %s",
                            C, rhs_t, ParameterTypeTuple!(Overloads[0])));
            }else{
                alias Overloads[0] FN;
            }
        }else{
            template IsDesiredOverload(alias fn) {
                enum bool IsDesiredOverload = is(ParameterTypeTuple!(fn)[0] == rhs_t);
            }
            alias Filter!(IsDesiredOverload, Overloads) Overloads1;
            static assert(Overloads1.length == 1, 
                    Format!("Cannot choose between %s", Overloads1));
            alias Overloads1[0] FN;
        }
    }
    static void call(T)() {
        alias wrapped_class_type!T type;
        type.tp_compare = &opcmp_wrap!(T, Inner!T.FN).func;
    }
    template shim(uint i) {
        // bah
        enum shim = "";
    }
}

struct OpIndex(index_t...) {
    enum bool needs_shim = false;
    template Inner(C) {
        static if(!__traits(hasMember, C, "opIndex")) {
            static assert(0, C.stringof ~ " has no index operator overloads");
        }
        static if(is(typeof(C.init.opIndex) == function)) {
            alias TypeTuple!(__traits(getOverloads, C, "opIndex")) Overloads;
            static if(index_t.length == 0 && Overloads.length > 1) {
                static assert(0, 
                        Format!("%s.opIndex: Cannot choose between %s",
                            C.stringof,Overloads.stringof));
            }else static if(index_t.length == 0) {
                alias Overloads[0] FN;
            }else{
                template IsDesiredOverload(alias fn) {
                    enum bool IsDesiredOverload = is(ParameterTypeTuple!fn == index_t);
                }
                alias Filter!(IsDesiredOverload, Overloads) Overloads1;
                static assert(Overloads1.length == 1, 
                        Format!("%s.opIndex: Cannot choose between %s",
                            C.stringof,Overloads1.stringof));
                alias Overloads1[0] FN;
            }
        }else static if(is(typeof(C.init.opIndex!(index_t)) == function)) {
            alias C.opIndex!(index_t) FN;
        }else{
            static assert(0, 
                    Format!("cannot get a handle on %s.opIndex", C.stringof));
        }
    }
    static void call(T)() {
        alias wrapped_class_type!T type;
        enum slot = "type.tp_as_mapping.mp_subscript";
        mixin(autoInitializeMethods());
        mixin(slot ~ " = &opindex_wrap!(T, Inner!T.FN).func;");
    }
    template shim(uint i) {
        // bah
        enum shim = "";
    }
}

struct OpIndexAssign(index_t...) {
    static assert(index_t.length != 1, 
            "opIndexAssign must have at least 2 parameters");
    enum bool needs_shim = false;
    template Inner(C) {
        static if(!__traits(hasMember, C, "opIndexAssign")) {
            static assert(0, C.stringof ~ " has no index operator overloads");
        }
        static if(is(typeof(C.init.opIndex) == function)) {
            alias TypeTuple!(__traits(getOverloads, C, "opIndexAssign")) Overloads;
            template IsValidOverload(alias fn) {
                enum bool IsValidOverload = ParameterTypeTuple!fn.length >= 2;
            }
            alias Filter!(IsValidOverload, Overloads) VOverloads;
            static if(VOverloads.length == 0 && Overloads.length != 0)
                static assert(0,
                        "opIndexAssign must have at least 2 parameters");
            static if(index_t.length == 0 && VOverloads.length > 1) {
                static assert(0, 
                        Format!("%s.opIndexAssign: Cannot choose between %s",
                            C.stringof,VOverloads.stringof));
            }else static if(index_t.length == 0) {
                alias VOverloads[0] FN;
            }else{
                template IsDesiredOverload(alias fn) {
                    enum bool IsDesiredOverload = is(ParameterTypeTuple!fn == index_t);
                }
                alias Filter!(IsDesiredOverload, VOverloads) Overloads1;
                static assert(Overloads1.length == 1, 
                        Format!("%s.opIndex: Cannot choose between %s",
                            C.stringof,Overloads1.stringof));
                alias Overloads1[0] FN;
            }
        }else static if(is(typeof(C.init.opIndexAssign!(index_t)) == function)) {
            alias C.opIndexAssign!(index_t) FN;
        }else{
            static assert(0, 
                    Format!("cannot get a handle on %s.opIndexAssign", C.stringof));
        }
    }
    static void call(T)() {
        alias wrapped_class_type!T type;
        enum slot = "type.tp_as_mapping.mp_ass_subscript";
        mixin(autoInitializeMethods());
        mixin(slot ~ " = &opindexassign_wrap!(T, Inner!T.FN).func;");
    }
    template shim(uint i) {
        // bah
        enum shim = "";
    }
}

struct OpSlice() {
    enum bool needs_shim = false;
    template Inner(C) {
        static if(!__traits(hasMember, C, "opSlice")) {
            static assert(0, C.stringof ~ " has no slice operator overloads");
        }
        static if(is(typeof(C.init.opSlice) == function)) {
            alias TypeTuple!(__traits(getOverloads, C, "opSlice")) Overloads;
            template IsDesiredOverload(alias fn) {
                enum bool IsDesiredOverload = is(ParameterTypeTuple!fn == 
                        TypeTuple!(Py_ssize_t,Py_ssize_t));
            }
            alias Filter!(IsDesiredOverload, Overloads) Overloads1;
            static assert(Overloads1.length != 0, 
                    Format!("%s.opSlice: must have overload %s",
                        C.stringof,TypeTuple!(Py_ssize_t,Py_ssize_t).stringof));
            static assert(Overloads1.length == 1, 
                    Format!("%s.opSlice: cannot choose between %s",
                        C.stringof,Overloads1.stringof));
            alias Overloads1[0] FN;
        }else{
            static assert(0, Format!("cannot get a handle on %s.opSlice",
                        C.stringof));
        }
    }
    static void call(T)() {
        alias wrapped_class_type!T type;
        enum slot = "type.tp_as_sequence.sq_slice";
        mixin(autoInitializeMethods());
        mixin(slot ~ " = &opslice_wrap!(T, Inner!T.FN).func;");
    }
    template shim(uint i) {
        // bah
        enum shim = "";
    }
}

struct OpSliceAssign(rhs_t = Guess) {
    enum bool needs_shim = false;
    template Inner(C) {
        static if(!__traits(hasMember, C, "opSliceAssign")) {
            static assert(0, C.stringof ~ " has no slice assignment operator overloads");
        }
        static if(is(typeof(C.init.opSliceAssign) == function)) {
            alias TypeTuple!(__traits(getOverloads, C, "opSliceAssign")) Overloads;
            template IsDesiredOverload(alias fn) {
                alias ParameterTypeTuple!fn ps;
                enum bool IsDesiredOverload = 
                    is(ps[1..3] == TypeTuple!(Py_ssize_t,Py_ssize_t));
            }
            alias Filter!(IsDesiredOverload, Overloads) Overloads1;
            static assert(Overloads1.length != 0, 
                    Format!("%s.opSliceAssign: must have overload %s",
                        C.stringof,TypeTuple!(Guess,Py_ssize_t,Py_ssize_t).stringof));
            static if(is(rhs_t == Guess)) {
                static assert(Overloads1.length == 1, 
                        Format!("%s.opSliceAssign: cannot choose between %s",
                            C.stringof,Overloads1.stringof));
                alias Overloads1[0] FN;
            }else{
                template IsDesiredOverload2(alias fn) {
                    alias ParameterTypeTuple!fn ps;
                    enum bool IsDesiredOverload2 = is(ps[0] == rhs_t);
                }
                alias Filter!(IsDesiredOverload2, Overloads1) Overloads2;
                static assert(Overloads2.length == 1, 
                        Format!("%s.opSliceAssign: cannot choose between %s",
                            C.stringof,Overloads2.stringof));
                alias Overloads2[0] FN;
            }
        }else{
            static assert(0, Format!("cannot get a handle on %s.opSlice",
                        C.stringof));
        }
    }
    static void call(T)() {
        alias wrapped_class_type!T type;
        enum slot = "type.tp_as_sequence.sq_ass_slice";
        mixin(autoInitializeMethods());
        mixin(slot ~ " = &opsliceassign_wrap!(T, Inner!T.FN).func;");
    }
    template shim(uint i) {
        // bah
        enum shim = "";
    }
}

struct OpCall(Args_t...) {
    enum bool needs_shim = false;

    template Inner(T) {
        alias TypeTuple!(__traits(getOverloads, T, "opCall")) Overloads;
        template IsDesiredOverload(alias fn) {
            alias ParameterTypeTuple!fn ps;
            enum bool IsDesiredOverload = is(ps == Args_t);
        }
        alias Filter!(IsDesiredOverload, Overloads) VOverloads;
        static if(VOverloads.length == 0) {
            static assert(0,
                    Format!("%s.opCall: cannot find signature %s", T.stringof, 
                        Args_t.stringof));
        }else static if(VOverloads.length == 1){
            alias VOverloads[0] FN;
        }else static assert(0,
                Format!("%s.%s: cannot choose between %s", T.stringof, nom,
                    VOverloads.stringof));
    }
    static void call(T)() {
        alias wrapped_class_type!T type;
        alias Inner!T.FN fn;
        type.tp_call = &opcall_wrap!(T, Inner!T.FN).func;
    }
    template shim(uint i) {
        // bah
        enum shim = "";
    }
}

template Len() {
    alias _Len!() Len;
}

template Len(alias fn) {
    alias _Len!(fn) Len;
}

struct _Len(fnt...) {
    enum bool needs_shim = false;
    template Inner(T) {
        static if(fnt.length == 0) {
            enum nom = "length";
        }else{
            enum nom = __traits(identifier, fnt[0]);
        }
        alias TypeTuple!(__traits(getOverloads, T, nom)) Overloads;
        template IsDesiredOverload(alias fn) {
            alias ParameterTypeTuple!fn ps;
            alias ReturnType!fn rt;
            enum bool IsDesiredOverload = is(rt : Py_ssize_t) && ps.length == 0;
        }
        alias Filter!(IsDesiredOverload, Overloads) VOverloads;
        static if(VOverloads.length == 0 && Overloads.length != 0) {
            static assert(0,
                    Format!("%s.%s must have signature %s", T.stringof, nom,
                        (Py_ssize_t function()).stringof));
        }else static if(VOverloads.length == 1){
            alias VOverloads[0] FN;
        }else static assert(0,
                Format!("%s.%s: cannot choose between %s", T.stringof, nom,
                    VOverloads.stringof));
    }
    static void call(T)() {
        alias wrapped_class_type!T type;
        enum slot = "type.tp_as_sequence.sq_length";
        mixin(autoInitializeMethods());
        mixin(slot ~ " = &length_wrap!(T, Inner!T.FN).func;");
    }
    template shim(uint i) {
        // bah
        enum shim = "";
    }
}


template param1(C) { 
    template param1(T) {alias ParameterTypeTuple!(T.Inner!C .FN)[0] param1; }
}

alias Pred!q{__traits(hasMember, A,"op")} IsOp;
alias Pred!q{A.stringof.startsWith("OpUnary!")} IsUn;
template IsBin(T...) {
    static if(T[0].stringof.startsWith("BinaryOperatorX!")) 
        enum bool IsBin = !T[0].isRight;
    else
        enum bool IsBin = false;
}
template IsBinR(T...) {
    static if(T[0].stringof.startsWith("BinaryOperatorX!")) 
        enum IsBinR = T[0].isRight;
    else
        enum IsBinR = false;
}

// handle all operator overloads. Ops must only contain operator overloads.
struct Operators(Ops...) {
    enum bool needs_shim = false;

    template BinOp(string op, T) {
        alias Pred!(Replace!(q{A.op == "OP"},"OP",op)) IsThisOp;
        alias Filter!(IsThisOp, Ops) Ops0;
        alias Filter!(IsBin, Ops0) OpsL;
        alias staticMap!(param1!T, OpsL) OpsLparams;
        static assert(OpsL.length <= 1, 
                Replace!("Cannot overload $T1 $OP x with types $T2", 
                    "$OP", op, "$T1", T.stringof, "$T2",  OpsLparams.stringof));
        alias Filter!(IsBinR, Ops0) OpsR;
        alias staticMap!(param1, OpsR) OpsRparams;
        static assert(OpsR.length <= 1, 
                Replace!("Cannot overload x $OP $T1 with types $T2", 
                    "$OP", op, "$T1", T.stringof, "$T2",  OpsRparams.stringof));
        static assert(op[$-1] != '=' || OpsR.length == 0, 
                "Cannot reflect assignment operator");

        static void call() {
            static if(OpsL.length + OpsR.length != 0) {
                alias wrapped_class_type!T type;
                enum slot = binaryslots[op];
                mixin(autoInitializeMethods());
                static if(op == "in") {
                    mixin(slot ~ " = &inop_wrap!(T, CW!OpsL, CW!OpsR).func;");
                }else static if(op == "^^" || op == "^^=") {
                    mixin(slot ~ " = &powop_wrap!(T, CW!OpsL, CW!OpsR).func;");
                }else {
                    mixin(slot ~ " = &binop_wrap!(T, CW!OpsL, CW!OpsR).func;");
                }
            }
        }

    }
    struct UnOp(string op, T) {
        alias Pred!(Replace!(q{A.op == "OP"},"OP",op)) IsThisOp;
        alias Filter!(IsUn, Filter!(IsThisOp, Ops)) Ops1;
        static assert(Ops1.length <= 1, 
                Replace!("Cannot have overloads of $OP$T1", 
                    "$OP", op, "$T1", T.stringof));
        static void call() {
            static if(Ops1.length != 0) {
                alias wrapped_class_type!T type;
                alias Ops1[0] Ops1_0;
                alias Ops1_0.Inner!T .FN fn;
                enum slot = unaryslots[op];
                mixin(autoInitializeMethods());
                mixin(slot ~ " = &opfunc_unary_wrap!(T, fn).func;");
            }
        }
    }

    static void call(T)() {
        alias NoDuplicates!(staticMap!(Pred!"A.op", Ops)) str_op_tuple;
        enum binops = binaryslots.keys();
        foreach(_op; str_op_tuple) {
            BinOp!(_op, T).call(); // noop if op is unary
            UnOp!(_op, T).call(); // noop if op is binary
        }
    }
}

/*
Params: each param is a Type which supports the interface

Param.needs_shim == false => Param.call!(T)
or 
Param.needs_shim == true => Param.call!(T, Shim)

    performs appropriate mutations to the PyTypeObject

Param.shim!(i) for i : Params[i] == Param

    generates a string to be mixed in to Shim type

where T is the type being wrapped, Shim is the wrapped type

*/
void wrap_class(T, Params...) (string docstring="", string modulename="") {
    _wrap_class!(T, symbolnameof!(T), Params).wrap_class(docstring, modulename);
}
/+
template _wrap_class(T, Params...) {
    mixin _wrap_class!(T, symbolnameof!(T), Params);
}
+/
//import std.stdio;
template _wrap_class(_T, string name, Params...) {
    static if (is(_T == class)) {
        pragma(msg, "wrap_class: " ~ name);
        alias pyd.make_wrapper.make_wrapper!(_T, Params).wrapper shim_class;
        //alias W.wrapper shim_class;
        alias _T T;
    } else {
        pragma(msg, "wrap_struct: '" ~ name ~ "'");
        alias void shim_class;
        alias _T* T;
    }
    void wrap_class(string docstring="", string modulename="") {
        alias wrapped_class_type!(T) type;
        //writefln("entering wrap_class for %s", typeid(T));
        //pragma(msg, "wrap_class, T is " ~ prettytypeof!(T));

        //Params params;
        //writefln("before params: tp_init is %s", type.tp_init);
        foreach (param; Params) {
            static if (param.needs_shim) {
                //mixin param.call!(T) PCall;
                param.call!(T, shim_class)();
            } else {
                param.call!(T)();
            }
        }
        //writefln("after params: tp_init is %s", type.tp_init);

        assert(Pyd_Module_p(modulename) !is null, "Must initialize module before wrapping classes.");
        string module_name = toString(python.PyModule_GetName(Pyd_Module_p(modulename)));

        //////////////////
        // Basic values //
        //////////////////
        type.ob_type      = python.PyType_Type_p();
        type.tp_basicsize = (wrapped_class_object!(T)).sizeof;
        type.tp_doc       = (docstring ~ "\0").ptr;
        type.tp_flags     = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE | Py_TPFLAGS_CHECKTYPES;
        //type.tp_repr      = &wrapped_repr!(T).repr;
        type.tp_methods   = wrapped_method_list!(T).ptr;
        type.tp_name      = (module_name ~ "." ~ name ~ "\0").ptr;

        /////////////////
        // Inheritance //
        /////////////////
        // Inherit classes from their wrapped superclass.
        static if (is(T B == super)) {
            foreach (C; B) {
                static if (is(C == class) && !is(C == Object)) {
                    if (is_wrapped!(C)) {
                        type.tp_base = &wrapped_class_type!(C);
                    }
                }
            }
        }

        ////////////////////////
        // Operator overloads //
        ////////////////////////

        Operators!(Filter!(IsOp, Params)).call!T();
        // its just that simple.

        //////////////////////////
        // Constructor wrapping //
        //////////////////////////
        // If a ctor wasn't supplied, try the default.
        // If the default ctor isn't available, and no ctors were supplied,
        // then this class cannot be instantiated from Python.
        // (Structs always use the default ctor.)
        static if (is(typeof(new T))) {
            if (type.tp_init is null) {
                static if (is(T == class)) {
                    type.tp_init = &wrapped_init!(shim_class).init;
                } else {
                    type.tp_init = &wrapped_struct_init!(T).init;
                }
            }
        }
        //writefln("after default check: tp_init is %s", type.tp_init);

        //////////////////
        // Finalization //
        //////////////////
        if (PyType_Ready(&type) < 0) {
            throw new Exception("Couldn't ready wrapped type!");
        }
        //writefln("after Ready: tp_init is %s", type.tp_init);
        python.Py_INCREF(cast(PyObject*)&type);
        python.PyModule_AddObject(Pyd_Module_p(modulename), (name~"\0").ptr, cast(PyObject*)&type);

        is_wrapped!(T) = true;
        static if (is(T == class)) {
            is_wrapped!(shim_class) = true;
            wrapped_classes[T.classinfo] = &type;
            wrapped_classes[shim_class.classinfo] = &type;
        }
        //writefln("leaving wrap_class for %s", typeid(T));
    }
}
////////////////
// DOCSTRINGS //
////////////////

struct Docstring {
    string name, doc;
}

void docstrings(T=void)(Docstring[] docs...) {
    static if (is(T == void)) {
        
    }
}

///////////////////////
// PYD API FUNCTIONS //
///////////////////////

// If the passed D reference has an existing Python object, return a borrowed
// reference to it. Otherwise, return null.
PyObject_BorrowedRef* get_existing_reference(T) (T t) {
    static if (is(T == class)) {
        auto range = wrapped_gc_objects.equalRange(cast(void*) t);
        if(range.empty) return null;
        return cast(PyObject_BorrowedRef*) range.front.py;
    } else {
        auto range = wrapped_gc_references!(T).equalRange(t);
        if(range.empty) return null;
        return cast(PyObject_BorrowedRef*) range.front.py;
    }
}

// Drop the passed D reference from the pool of held references.
void drop_reference(T) (T t) {
    static if (is(T == class)) {
        wrapped_gc_objects.removeKey(cast(void*)t);
    } else {
        wrapped_gc_references!(T).removeKey(t);
    }
}

// Add the passed D reference to the pool of held references.
void add_reference(T) (T t, PyObject* o) {
    static if (is(T == class)) {
        wrapped_gc_objects.insert(D2Py(cast(void*)t, o));
    } else {
        wrapped_gc_references!(T).insert(Dt2Py!T(t, o));
    }
}

PyObject* WrapPyObject_FromObject(T) (T t) {
    return WrapPyObject_FromTypeAndObject(&wrapped_class_type!(T), t);
}

/**
 * Returns a new Python object of a wrapped type.
 */
PyObject* WrapPyObject_FromTypeAndObject(T) (PyTypeObject* type, T t) {
    //alias wrapped_class_object!(T) wrapped_object;
    //alias wrapped_class_type!(T) type;
    if (is_wrapped!(T)) {
        // If this object is already wrapped, get the existing object.
        PyObject_BorrowedRef* obj_p = get_existing_reference(t);
        if (obj_p) {
            return OwnPyRef(obj_p);
        }
        // Otherwise, allocate a new object
        PyObject* obj = type.tp_new(type, null, null);
        // Set the contained instance
        WrapPyObject_SetObj(obj, t);
        return obj;
    } else {
        PyErr_SetString(PyExc_RuntimeError, ("Type " ~ objToStr(typeid(T)) ~ " is not wrapped by Pyd.").ptr);
        return null;
    }
}

/**
 * Returns the object contained in a Python wrapped type.
 */
T WrapPyObject_AsObject(T) (PyObject* _self) {
    alias wrapped_class_object!(T) wrapped_object;
    alias wrapped_class_type!(T) type;
    wrapped_object* self = cast(wrapped_object*)_self;
    if (!is_wrapped!(T)) {
        throw new Exception(format("Error extracting D object: Type %s is not wrapped.",objToStr(typeid(T))));
    }
    if (self is null) {
        throw new Exception("Error extracting D object: 'self' was null!");
    }
    static if (is(T == class)) {
        if (cast(Object)(self.d_obj) is null) {
            throw new Exception("Error extracting D object: Reference was not castable to Object!");
        }
        if (cast(T)cast(Object)(self.d_obj) is null) {
            throw new Exception(format("Error extracting D object: Object was not castable to type %s.",objToStr(typeid(T))));
        }
    }
    return self.d_obj;
}

/**
 * Sets the contained object in self to t.
 */
void WrapPyObject_SetObj(T) (PyObject* _self, T t) {
    alias wrapped_class_object!(T) obj;
    obj* self = cast(obj*)_self;
    if (t is self.d_obj) return;
    // Clean up the old object, if there is one
    if (self.d_obj !is null) {
        drop_reference(self.d_obj);
    }
    self.d_obj = t;
    // Handle the new one, if there is one
    if (t !is null) add_reference(self.d_obj, _self);
}

