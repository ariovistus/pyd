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
  Contains utilities for wrapping D classes.
*/
module pyd.class_wrap;

import deimos.python.Python;

import std.traits;
import std.conv;
import std.functional;
import std.typetuple;
import util.typelist;
import util.typeinfo;
import pyd.references;
import pyd.ctor_wrap;
import pyd.def;
import pyd.exception;
import pyd.func_wrap;
import pyd.make_object;
import pyd.make_wrapper;
import pyd.op_wrap;
import pyd.struct_wrap;

version(Pyd_with_StackThreads) static assert(0, "sorry - stackthreads are gone");

PyTypeObject*[ClassInfo] wrapped_classes;
template shim_class(T) {
    PyTypeObject* shim_class;
}

// kill
template wrapped_class_object(T) {
    alias PyObject wrapped_class_object;
}

void init_PyTypeObject(T)(ref PyTypeObject tipo) {
    Py_SET_REFCNT(&tipo, 1);
    tipo.tp_dealloc = &wrapped_methods!(T).wrapped_dealloc;
    tipo.tp_new = &wrapped_methods!(T).wrapped_new;
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

//-///////////////////
// STANDARD METHODS //
//-///////////////////

// Various wrapped methods
template wrapped_methods(T) {
    /// The generic "__new__" method
    extern(C)
    PyObject* wrapped_new(PyTypeObject* type, PyObject* args, PyObject* kwds) {
        return type.tp_alloc(type, 0);
    }

    // The generic dealloc method.
    extern(C)
    void wrapped_dealloc(PyObject* self) {
        // EMN: the *&%^^%! generic dealloc method is triggering a call to
        //  *&^%*%(! malloc for that delegate during a @(*$76*&!
        //  garbage collection
        //  Solution: don't use a *&%%^^! delegate in a destructor!
        static struct StackDelegate{
            PyObject* x;
            void dg() {
                remove_pyd_mapping!T(x);
                x.ob_type.tp_free(x);
            }
        }
        StackDelegate x;
        x.x = self;
        exception_catcher_nogc(&x.dg);
    }
}

// why we no use method_wrap ?
template wrapped_repr(T, alias fn) {
    import std.string: format;

    static assert(constCompatible(constness!T, constness!(typeof(fn))),
            format("constness mismatch instance: %s function: %s",
                T.stringof, typeof(fn).stringof));
    alias dg_wrapper!(T, typeof(&fn)) get_dg;
    /// The default repr method calls the class's toString.
    extern(C)
    PyObject* repr(PyObject* self) {
        return exception_catcher(delegate PyObject*() {
            auto dg = get_dg(get_d_reference!T(self), &fn);
            return d_to_python(dg());
        });
    }
}

private template ID(A){ alias A ID; }
private struct CW(A...){ alias A C; }

template IsProperty(alias T) {
    enum bool IsProperty =
        (functionAttributes!(T) & FunctionAttribute.property) != 0;
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
template IsAnySetter(alias T) {
    enum bool IsAnySetter = ParameterTypeTuple!T .length == 1;
}

// This template gets an alias to a property and derives the types of the
// getter form and the setter form. It requires that the getter form return the
// same type that the setter form accepts.
struct property_parts(alias p, string _mode) {
    import std.algorithm: countUntil;
    import std.string: format;

    alias ID!(__traits(parent, p)) Parent;
    enum nom = __traits(identifier, p);
    alias TypeTuple!(__traits(getOverloads, Parent, nom)) Overloads;
    static if(_mode == "" || countUntil(_mode, "r") != -1) {
        alias Filter!(IsGetter,Overloads) Getters;
        static if(_mode == "" && Getters.length == 0) {
            enum isgproperty = false;
            enum rmode = "";
        }else {
            static assert(Getters.length != 0,
                    format!("can't find property %s.%s getter",
                        Parent.stringof, nom));
            static assert(Getters.length == 1,
                    format!("can't handle property overloads of %s.%s getter (types %s)",
                        Parent.stringof, nom, staticMap!(ReturnType,Getters).stringof));
            alias Getters[0] GetterFn;
            alias typeof(&GetterFn) getter_type;
            enum isgproperty = IsProperty!GetterFn;
            enum rmode = "r";
        }
    }else {
        enum isgproperty = false;
        enum rmode = "";
    }
    //enum bool pred1 = _mode == "" || countUntil(_mode, "w") != -1;
    static if(_mode == "" || countUntil(_mode, "w") != -1) {
        static if(rmode == "r") {
            alias Filter!(IsSetter!(ReturnType!getter_type), Overloads) Setters;
        }else {
            alias Filter!(IsAnySetter, Overloads) Setters;
        }

        //enum bool pred2 = _mode == "" && Setters.length == 0;
        static if(_mode == "" && Setters.length == 0) {
            enum bool issproperty = false;
            enum string wmode = "";
        }else{
            static assert(Setters.length != 0, format("can't find property %s.%s setter", Parent.stringof, nom));
            static assert(Setters.length == 1,
                format("can't handle property overloads of %s.%s setter %s",
                    Parent.stringof, nom, Setters.stringof));
            alias Setters[0] SetterFn;
            alias typeof(&SetterFn) setter_type;
            static if(rmode == "r") {
                static assert(!(IsProperty!GetterFn ^ IsProperty!(Setters[0])),
                        format("%s.%s: getter and setter must both be @property or not @property",
                            Parent.stringof, nom));
            }
            enum issproperty = IsProperty!SetterFn;
            enum wmode = "w";
        }
    }else{
        enum issproperty = false;
        enum wmode = "";
    }

    static if(rmode != "") {
        alias ReturnType!(GetterFn) Type;
    }else static if(wmode != "") {
        alias ParameterTypeTuple!(SetterFn)[0] Type;
    }

    enum mode = rmode ~ wmode;
    enum bool isproperty = isgproperty || issproperty;
}

//
template wrapped_get(string fname, T, Parts) {
    // A generic wrapper around a "getter" property.
    extern(C)
    PyObject* func(PyObject* self, void* closure) {
        // method_wrap already catches exceptions
        return method_wrap!(T, Parts.GetterFn, fname).func(self, null, null);
    }
}

//
template wrapped_set(string fname, T, Parts) {
    // A generic wrapper around a "setter" property.
    extern(C)
    int func(PyObject* self, PyObject* value, void* closure) {
        PyObject* temp_tuple = PyTuple_New(1);
        if (temp_tuple is null) return -1;
        scope(exit) Py_DECREF(temp_tuple);
        Py_INCREF(value);
        PyTuple_SetItem(temp_tuple, 0, value);
        PyObject* res = method_wrap!(T, Parts.SetterFn, fname).func(self, temp_tuple, null);
        // If we get something back, we need to DECREF it.
        if (res) Py_DECREF(res);
        // If we don't, propagate the exception
        else return -1;
        // Otherwise, all is well.
        return 0;
    }
}

//-///////////////////////////
// CLASS WRAPPING INTERFACE //
//-///////////////////////////

//enum ParamType { Def, StaticDef, Property, Init, Parent, Hide, Iter, AltIter }
struct DoNothing {
    static void call(string classname, T) () {}
}

/**
Wraps a member function of the class.

Supports default arguments, typesafe variadic arguments, and python's
keyword arguments.

Params:
fn = The member function to wrap.
Options = Optional parameters. Takes Docstring!(docstring), PyName!(pyname),
and fn_t.
fn_t = The type of the function. It is only useful to specify this
       if more than one function has the same name as this one.
pyname = The name of the function as it will appear in Python. Defaults to
fn's name in D
docstring = The function's docstring. Defaults to "".
*/
struct Def(alias fn, Options...) {
    alias Args!("","", __traits(identifier,fn), "",Options) args;
    static if(args.rem.length) {
        alias args.rem[0] fn_t;
    }else {
        alias typeof(&fn) fn_t;
    }
    mixin _Def!(fn, args.pyname, fn_t, args.docstring);
}

template _Def(alias _fn, string name, fn_t, string docstring) {
    alias def_selector!(_fn,fn_t).FN func;
    static assert(!__traits(isStaticFunction, func)); // TODO
    static assert((functionAttributes!fn_t & (
                    FunctionAttribute.nothrow_|
                    FunctionAttribute.pure_|
                    FunctionAttribute.trusted|
                    FunctionAttribute.safe)) == 0,
            "pyd currently does not support pure, nothrow, @trusted, or @safe member functions");
    alias /*StripSafeTrusted!*/fn_t func_t;
    enum realname = __traits(identifier,func);
    enum funcname = name;
    enum min_args = minArgs!(func);
    enum bool needs_shim = false;

    static void call(string classname, T) () {
        alias ApplyConstness!(T, constness!(typeof(func))) cT;
        static PyMethodDef empty = { null, null, 0, null };
        alias wrapped_method_list!(T) list;
        list[$-1].ml_name = (name ~ "\0").ptr;
        list[$-1].ml_meth = cast(PyCFunction) &method_wrap!(cT, func, classname ~ "." ~ name).func;
        list[$-1].ml_flags = METH_VARARGS | METH_KEYWORDS;
        list[$-1].ml_doc = (docstring~"\0").ptr;
        list ~= empty;
        // It's possible that appending the empty item invalidated the
        // pointer in the type struct, so we renew it here.
        PydTypeObject!(T).tp_methods = list.ptr;
    }
    template shim(size_t i, T) {
        import util.replace: Replace;
        enum shim = Replace!(q{
            alias Params[$i] __pyd_p$i;
            $override ReturnType!(__pyd_p$i.func_t) $realname(ParameterTypeTuple!(__pyd_p$i.func_t) t) $attrs {
                return __pyd_get_overload!("$realname", __pyd_p$i.func_t).func!(ParameterTypeTuple!(__pyd_p$i.func_t))("$name", t);
            }
            alias T.$realname $realname;
        }, "$i",i,"$realname",realname, "$name", name,
        "$attrs", attrs_to_string(functionAttributes!func_t) ~ " " ~ tattrs_to_string!(func_t)(),
        "$override",
        // todo: figure out what's going on here
        (variadicFunctionStyle!func == Variadic.no ? "override":""));
    }
}

/**
Wraps a static member function of the class. Similar to pyd.def.def

Supports default arguments, typesafe variadic arguments, and python's
keyword arguments.

Params:
fn = The member function to wrap.
Options = Optional parameters. Takes Docstring!(docstring), PyName!(pyname),
and fn_t
fn_t = The type of the function. It is only useful to specify this
       if more than one function has the same name as this one.
pyname = The name of the function as it will appear in Python. Defaults to fn's
name in D.
docstring = The function's docstring. Defaults to "".
*/
struct StaticDef(alias fn, Options...) {
    alias Args!("","", __traits(identifier,fn), "",Options) args;
    static if(args.rem.length) {
        alias args.rem[0] fn_t;
    }else {
        alias typeof(&fn) fn_t;
    }
    mixin _StaticDef!(fn, args.pyname, fn_t, args.docstring);
}

mixin template _StaticDef(alias fn, string name, fn_t, string docstring) {
    alias def_selector!(fn,fn_t).FN func;
    static assert(__traits(isStaticFunction, func)); // TODO
    alias /*StripSafeTrusted!*/fn_t func_t;
    enum funcname = name;
    enum bool needs_shim = false;
    static void call(string classname, T) () {
        //pragma(msg, "class.static_def: " ~ name);
        static PyMethodDef empty = { null, null, 0, null };
        alias wrapped_method_list!(T) list;
        list[$-1].ml_name = (name ~ "\0").ptr;
        list[$-1].ml_meth = cast(PyCFunction) &function_wrap!(func, classname ~ "." ~ name).func;
        list[$-1].ml_flags = METH_VARARGS | METH_STATIC | METH_KEYWORDS;
        list[$-1].ml_doc = (docstring~"\0").ptr;
        list ~= empty;
        PydTypeObject!(T).tp_methods = list.ptr;
    }
    template shim(size_t i,T) {
        enum shim = "";
    }
}

/**
Wraps a property of the class.

Params:
fn = The property to wrap.
Options = Optional parameters. Takes Docstring!(docstring), PyName!(pyname),
and Mode!(mode)
pyname = The name of the property as it will appear in Python. Defaults to
fn's name in D.
mode = specifies whether this property is readable, writable. possible values
are "r", "w", "rw", and "" (in the latter case, automatically determine which
mode to use based on availability of getter and setter forms of fn). Defaults
to "".
docstring = The function's docstring. Defaults to "".
*/
struct Property(alias fn, Options...) {
    alias Args!("","", __traits(identifier,fn), "",Options) args;
    static assert(args.rem.length == 0, "Propery takes no other parameter");
    mixin _Property!(fn, args.pyname, args.mode, args.docstring);
}

template _Property(alias fn, string pyname, string _mode, string docstring) {
    import std.algorithm: countUntil;
    alias property_parts!(fn, _mode) parts;

    static if(parts.isproperty) {
        mixin _Member!(parts.nom, pyname, parts.mode, docstring, parts);

        template shim(size_t i, T) {
            enum shim = "";
        }
    }else {
        static if(countUntil(parts.mode,"r") != -1) {
            alias parts.getter_type get_t;
        }
        static if(countUntil(parts.mode,"w") != -1) {
            alias parts.setter_type set_t;
        }
        enum realname = __traits(identifier, fn);
        enum funcname = pyname;
        enum bool needs_shim = false;
        static void call(string classname, T) () {
            static PyGetSetDef empty = { null, null, null, null, null };
            wrapped_prop_list!(T)[$-1].name = (pyname ~ "\0").dup.ptr;
            static if (countUntil(parts.mode, "r") != -1) {
                alias ApplyConstness!(T, constness!(typeof(parts.GetterFn)))
                    cT_g;
                wrapped_prop_list!(T)[$-1].get =
                    &wrapped_get!(classname ~ "." ~ pyname, cT_g, parts).func;
            }
            static if (countUntil(parts.mode, "w") != -1) {
                alias ApplyConstness!(T, constness!(typeof(parts.SetterFn)))
                    cT_s;
                wrapped_prop_list!(T)[$-1].set =
                    &wrapped_set!(classname ~ "." ~ pyname,cT_s, parts).func;
            }
            wrapped_prop_list!(T)[$-1].doc = (docstring~"\0").dup.ptr;
            wrapped_prop_list!(T)[$-1].closure = null;
            wrapped_prop_list!(T) ~= empty;
            // It's possible that appending the empty item invalidated the
            // pointer in the type struct, so we renew it here.
            PydTypeObject!(T).tp_getset =
                wrapped_prop_list!(T).ptr;
        }
        template shim(size_t i, T) {
            import util.replace: Replace;
            static if(countUntil(parts.mode, "r") != -1) {
                enum getter = Replace!(q{
                override ReturnType!(__pyd_p$i.get_t) $realname() {
                    return __pyd_get_overload!("$realname", __pyd_p$i.get_t).func("$name");
                }
                } , "$i",i,"$realname",realname, "$name", pyname);
            }else{
                enum getter = "";
            }
            static if(countUntil(parts.mode, "w") != -1) {
                enum setter = Replace!(q{
                override ReturnType!(__pyd_p$i.set_t) $realname(ParameterTypeTuple!(__pyd_p$i.set_t) t) {
                    return __pyd_get_overload!("$realname", __pyd_p$i.set_t).func("$name", t);
                }
                }, "$i", i, "$realname",realname, "$name", pyname);
            }else {
                enum setter = "";
            }
            enum shim = Replace!(q{
                alias Params[$i] __pyd_p$i;
                $getter
                $setter;
            }, "$i",i, "$getter", getter, "$setter",setter);
        }
    }
}

/**
Wraps a method as the class's ___repr__ in Python.

Params:
fn = The property to wrap. Must have the signature string function().
*/
struct Repr(alias _fn) {
    alias def_selector!(_fn, string function()).FN fn;
    enum bool needs_shim = false;
    static void call(string classname, T)() {
        alias ApplyConstness!(T, constness!(typeof(fn))) cT;
        alias PydTypeObject!(T) type;
        type.tp_repr = &wrapped_repr!(cT, fn).repr;
    }
    template shim(size_t i,T) {
        enum shim = "";
    }
}

/**
Wraps the constructors of the class.

This template takes a single specialization of the ctor template
(see ctor_wrap.d), which describes a constructor that the class
supports. The default constructor need not be
specified, and will always be available if the class supports it.

Supports default arguments, typesafe variadic arguments, and python's
keyword arguments.

Params:
    cps = Parameter list of the constructor to be wrapped.

Bugs:
This currently does not support having multiple constructors with
the same number of arguments.
*/
struct Init(cps ...) {
    alias cps CtorParams;
    enum bool needs_shim = false;
    template Inner(T) {
        import std.string: format;

        alias NewParamT!T BaseT;
        alias TypeTuple!(__traits(getOverloads, BaseT, "__ctor")) Overloads;
        template IsDesired(alias ctor) {
            alias ParameterTypeTuple!ctor ps;
            enum bool IsDesired = is(ps == CtorParams);
        }
        alias Filter!(IsDesired, Overloads) VOverloads;
        static if(VOverloads.length == 0) {
            template concatumStrings(s...) {
                static if(s.length == 0) {
                    enum concatumStrings = "";
                }else {
                    enum concatumStrings = T.stringof ~ (ParameterTypeTuple!(s[0])).stringof ~ "\n" ~ concatumStrings!(s[1 .. $]); 
                }
            }
            alias allOverloadsString = concatumStrings!(Overloads);
            static assert(false,
                    format("%s: Cannot find constructor with params %s among\n %s",
                        T.stringof, CtorParams.stringof, allOverloadsString));
        }else{
            alias VOverloads[0] FN;
            alias ParameterTypeTuple!FN Pt;
            //https://issues.dlang.org/show_bug.cgi?id=17192
            //alias ParameterDefaultValueTuple!FN Pd;
            import util.typeinfo : WorkaroundParameterDefaults;
            alias Pd = WorkaroundParameterDefaults!FN;
        }
    }

    static void call(string classname, T)() {
    }

    template shim(size_t i, T) {
        import util.replace: Replace;
        import std.string: format;
        enum params = getparams!(Inner!T.FN,
                format("__pyd_p%s.Inner!T.Pt",i),
                format("__pyd_p%s.Inner!T.Pd",i));
        alias ParameterIdentifierTuple!(Inner!T.FN) paramids;
        enum shim = Replace!(q{
            alias Params[$i] __pyd_p$i;
            this($params) {
                super($ids);
            }
        }, "$i", i, "$params", params, "$ids", Join!(",", paramids));
    }
}

template IsInit(T) {
    enum bool IsInit = __traits(hasMember, T, "CtorParams");
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

string getBinarySlot(string op) {
    version(Python_3_0_Or_Later) {
        if (op == "/") return "type.tp_as_number.nb_true_divide";
        if (op == "/=") return "type.tp_as_number.nb_inplace_true_divide";
    }
    return binaryslots[op];
}

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
        import std.algorithm: countUntil;
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
        import std.string: format;

        enum fn_str1 = "Alias!(C."~nom~"!(op))";
        enum fn_str2 = "C."~nom~"!(op,rhs_t)";
        enum string OP = op;
        static if(!__traits(hasMember, C, nom)) {
            static assert(0, C.stringof ~ " has no "~(isR ?"reflected ":"")~
                    "binary operator overloads");
        }
        template Alias(alias fn) {
            alias fn Alias;
        }
        static if(is(typeof(mixin(fn_str1)) == function)) {
            static if(_op == "/") {
                pragma(msg, "getted here 1");
                pragma(msg, C.stringof);
            }
            alias ParameterTypeTuple!(typeof(mixin(fn_str1)))[0] RHS_T;
            alias ReturnType!(typeof(mixin(fn_str1))) RET_T;
            mixin("alias " ~ fn_str1 ~ " FN;");
            static if(!is(rhs_t == Guess))
                static assert(is(RHS_T == rhs_t),
                        format("expected typeof(rhs) = %s, found %s",
                            rhs.stringof, RHS_T.stringof));
        }else static if(is(rhs_t == Guess)) {
            static assert(false,
                    format("Operator %s: Cannot determine type of rhs", op));
        } else static if(is(typeof(mixin(fn_str2)) == function)) {
            alias rhs_t RHS_T;
            alias ReturnType!(typeof(mixin(fn_str2))) RET_T;
            mixin("alias "~fn_str2~" FN;");
        } else static assert(false, "Cannot get operator overload");
    }

    static void call(string classname, T)() {
        // can't handle __op__ __rop__ pairs here
    }

    template shim(size_t i, T) {
        // bah
        enum shim = "";
    }
}

/**
Wrap a binary operator overload.

Example:
---
class Foo{
    int _j;
    int opBinary(string op)(int i) if(op == "+"){
        return i+_j;
    }
    int opBinaryRight(string op)(int i) if(op == "+"){
        return i+_j;
    }
}

class_wrap!(Foo,
    OpBinary!("+"),
    OpBinaryRight!("+"));
---

Params:
    op = Operator to wrap
    rhs_t = (optional) Type of opBinary's parameter for disambiguation if
    there are multiple overloads.
Bugs:
    Issue 8602 prevents disambiguation for case X opBinary(string op, T)(T t);
  */
template OpBinary(string op, rhs_t = Guess) if(IsPyBinary(op) && op != "in"){
    alias BinaryOperatorX!(op, false, rhs_t) OpBinary;
}

/// ditto
template OpBinaryRight(string op, lhs_t = Guess) if(IsPyBinary(op)) {
    alias BinaryOperatorX!(op, true, lhs_t) OpBinaryRight;
}

/**
  Wrap a unary operator overload.
*/
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
    static void call(string classname, T)() {
        alias PydTypeObject!T type;
        enum slot = unaryslots[op];
        mixin(autoInitializeMethods());
        mixin(slot ~ " = &opfunc_unary_wrap!(T, Inner!T .FN).func;");
    }
    template shim(size_t i,T) {
        // bah
        enum shim = "";
    }
}

/**
  Wrap an operator assignment overload.

Example:
---
class Foo{
    int _j;
    void opOpAssign(string op)(int i) if(op == "+"){
        _j = i;
    }
}

class_wrap!(Foo,
    OpAssign!("+"));
---
Params:
    op = Base operator to wrap
    rhs_t = (optional) Type of opOpAssign's parameter for disambiguation if
    there are multiple overloads.
*/
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
                        format("expected typeof(rhs) = %s, found %s",
                            rhs.stringof, RHS_T.stringof));
        }else static if(is(rhs_t == Guess)) {
            static assert(false, "Cannot determine type of rhs");
        } else static if(is(typeof(C.opOpAssign!(_op,rhs_t)) == function)) {
            alias rhs_t RHS_T;
            alias ReturnType!(typeof(C.opOpAssign!(_op,rhs_t))) RET_T;
            alias C.opOpAssign!(_op,rhs_t) FN;
        } else static assert(false, "Cannot get operator assignment overload");
    }
    static void call(string classname, T)() {
        alias PydTypeObject!T type;
        enum slot = getBinarySlot(op);
        mixin(autoInitializeMethods());
        alias CW!(TypeTuple!(OpAssign)) OpAsg;
        alias CW!(TypeTuple!()) Nop;
        static if(op == "^^=")
            mixin(slot ~ " = &powopasg_wrap!(T, Inner!T.FN).func;");
        else
            mixin(slot ~ " = &binopasg_wrap!(T, Inner!T.FN).func;");
    }

    template shim(size_t i,T) {
        // bah
        enum shim = "";
    }
}

// struct types could probably take any parameter type
// class types must take Object
/**
  Wrap opCmp.

Params:
    rhs_t = (optional) Type of opCmp's parameter for disambiguation if there
    are multiple overloads (for classes it will always be Object).
  */
struct OpCompare(_rhs_t = Guess) {
    enum bool needs_shim = false;


    template Inner(C) {
        import std.string: format;
        static if(is(_rhs_t == Guess) && is(C == class)) {
            alias Object rhs_t;
        }else {
            alias _rhs_t rhs_t;
        }
        static if(!__traits(hasMember, C, "opCmp")) {
            static assert(0, C.stringof ~ " has no comparison operator overloads");
        }
        static if(!is(typeof(C.init.opCmp) == function)) {
            static assert(0, format("why is %s.opCmp not a function?",C));
        }
        alias TypeTuple!(__traits(getOverloads, C, "opCmp")) Overloads;
        static if(is(rhs_t == Guess) && Overloads.length > 1) {
            static assert(0, format("Cannot choose between %s", Overloads));
        }else static if(Overloads.length == 1) {
            static if(!is(rhs_t == Guess) &&
                !is(ParameterTypeTuple!(Overloads[0])[0] == rhs_t)) {
                static assert(0, format("%s.opCmp: expected param %s, got %s",
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
                    format("Cannot choose between %s", Overloads1));
            alias Overloads1[0] FN;
        }
    }
    static void call(string classname, T)() {
        alias PydTypeObject!T type;
        alias ApplyConstness!(T, constness!(typeof(Inner!T.FN))) cT;
        type.tp_richcompare = &rich_opcmp_wrap!(cT, Inner!T.FN).func;
    }
    template shim(size_t i,T) {
        // bah
        enum shim = "";
    }
}

/**
  Wrap opIndex, opIndexAssign.

Params:
    index_t = (optional) Types of opIndex's parameters for disambiguation if
    there are multiple overloads.
*/
struct OpIndex(index_t...) {
    enum bool needs_shim = false;
    template Inner(C) {
        import std.string: format;

        static if(!__traits(hasMember, C, "opIndex")) {
            static assert(0, C.stringof ~ " has no index operator overloads");
        }
        static if(is(typeof(C.init.opIndex) == function)) {
            alias TypeTuple!(__traits(getOverloads, C, "opIndex")) Overloads;
            static if(index_t.length == 0 && Overloads.length > 1) {
                static assert(0,
                        format("%s.opIndex: Cannot choose between %s",
                            C.stringof,Overloads.stringof));
            }else static if(index_t.length == 0) {
                alias Overloads[0] FN;
            }else{
                template IsDesiredOverload(alias fn) {
                    enum bool IsDesiredOverload = is(ParameterTypeTuple!fn == index_t);
                }
                alias Filter!(IsDesiredOverload, Overloads) Overloads1;
                static assert(Overloads1.length == 1,
                        format("%s.opIndex: Cannot choose between %s",
                            C.stringof,Overloads1.stringof));
                alias Overloads1[0] FN;
            }
        }else static if(is(typeof(C.init.opIndex!(index_t)) == function)) {
            alias C.opIndex!(index_t) FN;
        }else{
            static assert(0,
                    format("cannot get a handle on %s.opIndex", C.stringof));
        }
    }
    static void call(string classname, T)() {
        /*
        alias PydTypeObject!T type;
        enum slot = "type.tp_as_mapping.mp_subscript";
        mixin(autoInitializeMethods());
        mixin(slot ~ " = &opindex_wrap!(T, Inner!T.FN).func;");
        */
    }
    template shim(size_t i,T) {
        // bah
        enum shim = "";
    }
}

/// ditto
struct OpIndexAssign(index_t...) {
    static assert(index_t.length != 1,
            "opIndexAssign must have at least 2 parameters");
    enum bool needs_shim = false;
    template Inner(C) {
        import std.string: format;

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
                        format("%s.opIndexAssign: Cannot choose between %s",
                            C.stringof,VOverloads.stringof));
            }else static if(index_t.length == 0) {
                alias VOverloads[0] FN;
            }else{
                template IsDesiredOverload(alias fn) {
                    enum bool IsDesiredOverload = is(ParameterTypeTuple!fn == index_t);
                }
                alias Filter!(IsDesiredOverload, VOverloads) Overloads1;
                static assert(Overloads1.length == 1,
                        format("%s.opIndex: Cannot choose between %s",
                            C.stringof,Overloads1.stringof));
                alias Overloads1[0] FN;
            }
        }else static if(is(typeof(C.init.opIndexAssign!(index_t)) == function)) {
            alias C.opIndexAssign!(index_t) FN;
        }else{
            static assert(0,
                    format("cannot get a handle on %s.opIndexAssign", C.stringof));
        }
    }
    static void call(string classname, T)() {
        /*
        alias PydTypeObject!T type;
        enum slot = "type.tp_as_mapping.mp_ass_subscript";
        mixin(autoInitializeMethods());
        mixin(slot ~ " = &opindexassign_wrap!(T, Inner!T.FN).func;");
        */
    }
    template shim(size_t i,T) {
        // bah
        enum shim = "";
    }
}

/**
  Wrap opSlice.

  Requires signature
---
Foo.opSlice(Py_ssize_t, Py_ssize_t);
---
 This is a limitation of the C/Python API.
  */
struct OpSlice() {
    enum bool needs_shim = false;
    template Inner(C) {
        import std.string: format;

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
                    format("%s.opSlice: must have overload %s",
                        C.stringof,TypeTuple!(Py_ssize_t,Py_ssize_t).stringof));
            static assert(Overloads1.length == 1,
                    format("%s.opSlice: cannot choose between %s",
                        C.stringof,Overloads1.stringof));
            alias Overloads1[0] FN;
        }else{
            static assert(0, format("cannot get a handle on %s.opSlice",
                        C.stringof));
        }
    }
    static void call(string classname, T)() {
        /*
        alias PydTypeObject!T type;
        enum slot = "type.tp_as_sequence.sq_slice";
        mixin(autoInitializeMethods());
        mixin(slot ~ " = &opslice_wrap!(T, Inner!T.FN).func;");
        */
    }
    template shim(size_t i,T) {
        // bah
        enum shim = "";
    }
}

/**
  Wrap opSliceAssign.

  Requires signature
---
Foo.opSliceAssign(Value,Py_ssize_t, Py_ssize_t);
---
 This is a limitation of the C/Python API.
  */
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
                    format("%s.opSliceAssign: must have overload %s",
                        C.stringof,TypeTuple!(Guess,Py_ssize_t,Py_ssize_t).stringof));
            static if(is(rhs_t == Guess)) {
                static assert(Overloads1.length == 1,
                        format("%s.opSliceAssign: cannot choose between %s",
                            C.stringof,Overloads1.stringof));
                alias Overloads1[0] FN;
            }else{
                template IsDesiredOverload2(alias fn) {
                    alias ParameterTypeTuple!fn ps;
                    enum bool IsDesiredOverload2 = is(ps[0] == rhs_t);
                }
                alias Filter!(IsDesiredOverload2, Overloads1) Overloads2;
                static assert(Overloads2.length == 1,
                        format("%s.opSliceAssign: cannot choose between %s",
                            C.stringof,Overloads2.stringof));
                alias Overloads2[0] FN;
            }
        }else{
            static assert(0, format("cannot get a handle on %s.opSlice",
                        C.stringof));
        }
    }
    static void call(string classname, T)() {
        /*
        alias PydTypeObject!T type;
        enum slot = "type.tp_as_sequence.sq_ass_slice";
        mixin(autoInitializeMethods());
        mixin(slot ~ " = &opsliceassign_wrap!(T, Inner!T.FN).func;");
        */
    }
    template shim(size_t i,T) {
        // bah
        enum shim = "";
    }
}

/**
  wrap opCall. The parameter types of opCall must be specified.
*/
struct OpCall(Args_t...) {
    enum bool needs_shim = false;

    template Inner(T) {
        import std.string: format;

        alias TypeTuple!(__traits(getOverloads, T, "opCall")) Overloads;
        template IsDesiredOverload(alias fn) {
            alias ParameterTypeTuple!fn ps;
            enum bool IsDesiredOverload = is(ps == Args_t);
        }
        alias Filter!(IsDesiredOverload, Overloads) VOverloads;
        static if(VOverloads.length == 0) {
            static assert(0,
                    format("%s.opCall: cannot find signature %s", T.stringof,
                        Args_t.stringof));
        }else static if(VOverloads.length == 1){
            alias VOverloads[0] FN;
        }else static assert(0,
                format("%s.%s: cannot choose between %s", T.stringof, nom,
                    VOverloads.stringof));
    }
    static void call(string classname, T)() {
        alias PydTypeObject!T type;
        alias Inner!T.FN fn;
        alias ApplyConstness!(T, constness!(typeof(fn))) cT;
        type.tp_call = &opcall_wrap!(cT, fn).func;
    }
    template shim(size_t i,T) {
        // bah
        enum shim = "";
    }
}

/**
  Wraps Foo.length or another function as python's ___len__ function.

  Requires signature
---
Py_ssize_t length();
---
  This is a limitation of the C/Python API.
  */
template Len() {
    alias _Len!() Len;
}

/// ditto
template Len(alias fn) {
    alias _Len!(fn) Len;
}

struct _Len(fnt...) {
    enum bool needs_shim = false;
    template Inner(T) {
        import std.string: format;

        static if(fnt.length == 0) {
            enum nom = "length";
        }else{
            enum nom = __traits(identifier, fnt[0]);
        }
        alias TypeTuple!(__traits(getOverloads, T, nom)) Overloads;
        template IsDesiredOverload(alias fn) {
            alias ParameterTypeTuple!fn ps;
            alias ReturnType!fn rt;
            enum bool IsDesiredOverload = isImplicitlyConvertible!(rt,Py_ssize_t) && ps.length == 0;
        }
        alias Filter!(IsDesiredOverload, Overloads) VOverloads;
        static if(VOverloads.length == 0 && Overloads.length != 0) {
            static assert(0,
                    format("%s.%s must have signature %s", T.stringof, nom,
                        (Py_ssize_t function()).stringof));
        }else static if(VOverloads.length == 1){
            alias VOverloads[0] FN;
        }else static assert(0,
                format("%s.%s: cannot choose between %s", T.stringof, nom,
                    VOverloads.stringof));
    }
    static void call(string classname, T)() {
        alias PydTypeObject!T type;
        enum slot = "type.tp_as_sequence.sq_length";
        mixin(autoInitializeMethods());
        mixin(slot ~ " = &length_wrap!(T, Inner!T.FN).func;");
    }
    template shim(size_t i,T) {
        // bah
        enum shim = "";
    }
}


template param1(C) {
    template param1(T) {alias ParameterTypeTuple!(T.Inner!C .FN)[0] param1; }
}

enum IsOp(A) = __traits(hasMember, A, "op");

template IsUn(A) {
    import std.algorithm: startsWith;
    enum IsUn = A.stringof.startsWith("OpUnary!");
}

template IsBin(T...) {
    import std.algorithm: startsWith;
    static if(T[0].stringof.startsWith("BinaryOperatorX!"))
        enum bool IsBin = !T[0].isRight;
    else
        enum bool IsBin = false;
}
template IsBinR(T...) {
    import std.algorithm: startsWith;
    static if(T[0].stringof.startsWith("BinaryOperatorX!"))
        enum IsBinR = T[0].isRight;
    else
        enum IsBinR = false;
}

// handle all operator overloads. Ops must only contain operator overloads.
struct Operators(Ops...) {
    import util.replace: Replace;
    enum bool needs_shim = false;

    template BinOp(string op, T) {
        enum IsThisOp(A) = A.op == op;
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
                alias PydTypeObject!T type;
                enum slot = getBinarySlot(op);
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
        import util.replace: Replace;
        enum IsThisOp(A) = A.op == op;
        alias Filter!(IsUn, Filter!(IsThisOp, Ops)) Ops1;
        static assert(Ops1.length <= 1,
                Replace!("Cannot have overloads of $OP$T1",
                    "$OP", op, "$T1", T.stringof));
        static void call() {
            static if(Ops1.length != 0) {
                alias PydTypeObject!T type;
                alias Ops1[0] Ops1_0;
                alias Ops1_0.Inner!T .FN fn;
                enum slot = unaryslots[op];
                mixin(autoInitializeMethods());
                mixin(slot ~ " = &opfunc_unary_wrap!(T, fn).func;");
            }
        }
    }

    static void call(T)() {
        enum GetOp(A) = A.op;
        alias NoDuplicates!(staticMap!(GetOp, Ops)) str_op_tuple;
        enum binops = binaryslots.keys();
        foreach(_op; str_op_tuple) {
            BinOp!(_op, T).call(); // noop if op is unary
            UnOp!(_op, T).call(); // noop if op is binary
        }
    }
}

struct Constructors(string classname, Ctors...) {
    enum bool needs_shim = true;

    static void call(T, Shim)() {
        alias PydTypeObject!T type;
        alias NewParamT!T U;
        static if(Ctors.length) {
            type.tp_init = &wrapped_ctors!(classname, T, Shim, Ctors).func;
        }else {
            // If a ctor wasn't supplied, try the default.
            // If the default ctor isn't available, and no ctors were supplied,
            // then this class cannot be instantiated from Python.
            // (Structs always use the default ctor.)
            static if (is(typeof(new U))) {
                static if (is(U == class)) {
                    type.tp_init = &wrapped_init!(Shim).init;
                } else {
                    type.tp_init = &wrapped_struct_init!(U).init;
                }
            }
        }
    }
}

template IsDef(string pyname) {
    template IsDef(Params...) {
        import std.algorithm: startsWith;
        static if(Params[0].stringof.startsWith("Def!") &&
                __traits(hasMember,Params[0], "funcname")) {
            enum bool IsDef = (Params[0].funcname == pyname);
        }else{
            enum bool IsDef = false;
        }
    }
}
struct Iterator(Params...) {
    alias Filter!(IsDef!"__iter__", Params) Iters;
    alias Filter!(IsDef!"next", Params) Nexts;
    enum bool needs_shim = false;
    static void call(T)() {
        alias PydTypeObject!T type;
        import std.range;
        static if(Iters.length == 1 && (Nexts.length == 1 || isInputRange!(ReturnType!(Iters[0].func)))) {
            version(Python_3_0_Or_Later) {
            }else{
                type.tp_flags |= Py_TPFLAGS_HAVE_ITER;
            }
            type.tp_iter = &opiter_wrap!(T, Iters[0].func).func;
            static if(Nexts.length == 1)
                type.tp_iternext = &opiter_wrap!(T, Nexts[0].func).func;
        }
    }
}

template IsOpIndex(P...) {
    import std.algorithm: startsWith;
    enum bool IsOpIndex = P[0].stringof.startsWith("OpIndex!");
}
template IsOpIndexAssign(P...) {
    import std.algorithm: startsWith;
    enum bool IsOpIndexAssign = P[0].stringof.startsWith("OpIndexAssign!");
}
template IsOpSlice(P...) {
    import std.algorithm: startsWith;
    enum bool IsOpSlice = P[0].stringof.startsWith("OpSlice!");
}
template IsOpSliceAssign(P...) {
    import std.algorithm: startsWith;
    enum bool IsOpSliceAssign = P[0].stringof.startsWith("OpSliceAssign!");
}
template IsLen(P...) {
    import std.algorithm: startsWith;
    enum bool IsLen = P[0].stringof.startsWith("Len!");
}
/*
   Extended slice syntax goes through mp_subscript, mp_ass_subscript,
   not sq_slice, sq_ass_slice.

TODO: Python's extended slicing is more powerful than D's. We should expose
this.
*/
struct IndexSliceMerge(Params...) {
    alias Filter!(IsOpIndex, Params) OpIndexs;
    alias Filter!(IsOpIndexAssign, Params) OpIndexAssigns;
    alias Filter!(IsOpSlice, Params) OpSlices;
    alias Filter!(IsOpSliceAssign, Params) OpSliceAssigns;
    alias Filter!(IsLen, Params) Lens;

    static assert(OpIndexs.length <= 1);
    static assert(OpIndexAssigns.length <= 1);
    static assert(OpSlices.length <= 1);
    static assert(OpSliceAssigns.length <= 1);

    static void call(T)() {
        alias PydTypeObject!T type;
        static if(OpIndexs.length + OpSlices.length) {
            {
                enum slot = "type.tp_as_mapping.mp_subscript";
                mixin(autoInitializeMethods());
                mixin(slot ~ " = &op_func!(T);");
            }
        }
        static if(OpIndexAssigns.length + OpSliceAssigns.length) {
            {
                enum slot = "type.tp_as_mapping.mp_ass_subscript";
                mixin(autoInitializeMethods());
                mixin(slot ~ " = &ass_func!(T);");
            }
        }
    }


    static extern(C) PyObject* op_func(T)(PyObject* self, PyObject* key) {
        import std.string: format;

        static if(OpIndexs.length) {
            version(Python_2_5_Or_Later) {
                Py_ssize_t i;
                if(!PyIndex_Check(key)) goto slice;
                i = PyNumber_AsSsize_t(key, PyExc_IndexError);
            }else{
                C_long i;
                if(!PyInt_Check(key)) goto slice;
                i = PyLong_AsLong(key);
            }
            if(i == -1 && PyErr_Occurred()) {
                return null;
            }
            alias OpIndexs[0] OpIndex0;
            return opindex_wrap!(T, OpIndex0.Inner!T.FN).func(self, key);
        }
slice:
        static if(OpSlices.length) {
            if(PySlice_Check(key)) {
                Py_ssize_t len = PyObject_Length(self);
                Py_ssize_t start, stop, step, slicelength;
                if(PySlice_GetIndicesEx(key, len,
                            &start, &stop, &step, &slicelength) < 0) {
                    return null;
                }
                if(step != 1) {
                    PyErr_SetString(PyExc_TypeError,
                            "slice steps not supported in D");
                    return null;
                }
                alias OpSlices[0] OpSlice0;
                return opslice_wrap!(T, OpSlice0.Inner!T.FN).func(
                        self, start, stop);
            }
        }
        PyErr_SetString(PyExc_TypeError, format(
                    "index type '%s' not supported\0", to!string(key.ob_type.tp_name)).ptr);
        return null;
    }

    static extern(C) int ass_func(T)(PyObject* self, PyObject* key,
            PyObject* val) {
        import std.string: format;

        static if(OpIndexAssigns.length) {
            version(Python_2_5_Or_Later) {
                Py_ssize_t i;
                if(!PyIndex_Check(key)) goto slice;
                i = PyNumber_AsSsize_t(key, PyExc_IndexError);
            }else{
                C_long i;
                if(!PyInt_Check(key)) goto slice;
                i = PyLong_AsLong(key);
            }
            if(i == -1 && PyErr_Occurred()) {
                return -1;
            }
            alias OpIndexAssigns[0] OpIndexAssign0;
            return opindexassign_wrap!(T, OpIndexAssign0.Inner!T.FN).func(
                    self, key, val);
        }
slice:
        static if(OpSliceAssigns.length) {
            if(PySlice_Check(key)) {
                Py_ssize_t len = PyObject_Length(self);
                Py_ssize_t start, stop, step, slicelength;
                if(PySlice_GetIndicesEx(key, len,
                            &start, &stop, &step, &slicelength) < 0) {
                    return -1;
                }
                if(step != 1) {
                    PyErr_SetString(PyExc_TypeError,
                            "slice steps not supported in D");
                    return -1;
                }
                alias OpSliceAssigns[0] OpSliceAssign0;
                return opsliceassign_wrap!(T, OpSliceAssign0.Inner!T.FN).func(
                        self, start, stop, val);
            }
        }
        PyErr_SetString(PyExc_TypeError, format(
                    "assign index type '%s' not supported\0", to!string(key.ob_type.tp_name)).ptr);
        return -1;
    }
}

/*
Params: each param is a Type which supports the interface

Param.needs_shim == false => Param.call!(pyclassname, T)
or
Param.needs_shim == true => Param.call!(pyclassname,T, Shim)

    performs appropriate mutations to the PyTypeObject

Param.shim!(i,T) for i : Params[i] == Param

    generates a string to be mixed in to Shim type

where T is the type being wrapped, Shim is the wrapped type

*/

/**
  Wrap a class.

Params:
    T = The class being wrapped.
    Params = Mixture of definitions of members of T to be wrapped and
    optional arguments.
    Concerning optional arguments, accepts PyName!(pyname), ModuleName!(modulename), and Docstring!(docstring).
    pyname = The name of the class as it will appear in Python. Defaults to
    T's name in D
    modulename = The name of the python module in which the wrapped class
            resides. Defaults to "".
    docstring = The class's docstring. Defaults to "".
  */
void wrap_class(T, Params...)() {
    alias Args!("","", __traits(identifier,T), "",Params) args;
    _wrap_class!(T, args.pyname, args.docstring, args.modulename, args.rem).wrap_class();
}
template _wrap_class(_T, string name, string docstring, string modulename, Params...) {
    import std.conv;
    import util.typelist;
    static if (is(_T == class)) {
        //pragma(msg, "wrap_class: " ~ name);
        alias pyd.make_wrapper.make_wrapper!(_T, Params).wrapper shim_class;
        //alias W.wrapper shim_class;
        alias _T T;
    } else {
        //pragma(msg, "wrap_struct: '" ~ name ~ "'");
        alias void shim_class;
        alias _T* T;
    }
    void wrap_class() {
        if(!Pyd_Module_p(modulename)) {
            if(should_defer_class_wrap(modulename, name)) {
                defer_class_wrap(modulename, name,  toDelegate(&wrap_class));
                return;
            }
        }
        alias PydTypeObject!(T) type;
        init_PyTypeObject!T(type);

        foreach (param; Params) {
            static if (param.needs_shim) {
                param.call!(name, T, shim_class)();
            } else {
                param.call!(name,T)();
            }
        }

        assert(Pyd_Module_p(modulename) !is null, "Must initialize module '" ~ modulename ~ "' before wrapping classes.");
        string module_name = to!string(PyModule_GetName(Pyd_Module_p(modulename)));

        //////////////////
        // Basic values //
        //////////////////
        Py_SET_TYPE(&type, &PyType_Type);
        type.tp_basicsize = PyObject.sizeof;
        type.tp_doc       = (docstring ~ "\0").ptr;
        version(Python_3_0_Or_Later) {
            type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
        }else{
            type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE | Py_TPFLAGS_CHECKTYPES;
        }
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
                        type.tp_base = &PydTypeObject!(C);
                    }
                }
            }
        }

        ////////////////////////
        // Operator overloads //
        ////////////////////////

        Operators!(Filter!(IsOp, Params)).call!T();
        // its just that simple.

        IndexSliceMerge!(Params).call!T();
        // indexing and slicing aren't exactly simple.

        //////////////////////////
        // Constructor wrapping //
        //////////////////////////
        Constructors!(name, Filter!(IsInit, Params)).call!(T, shim_class)();

        //////////////////////////
        // Iterator wrapping    //
        //////////////////////////
        Iterator!(Params).call!(T)();


        //////////////////
        // Finalization //
        //////////////////
        if (PyType_Ready(&type) < 0) {
            throw new Exception("Couldn't ready wrapped type!");
        }
        Py_INCREF(cast(PyObject*)&type);
        PyModule_AddObject(Pyd_Module_p(modulename), (name~"\0").ptr, cast(PyObject*)&type);

        is_wrapped!(T) = true;
        static if (is(T == class)) {
            is_wrapped!(shim_class) = true;
            wrapped_classes[T.classinfo] = &type;
            wrapped_classes[shim_class.classinfo] = &type;
        }
    }
}

