/*
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

module pyd.references;

import std.traits;
import std.typetuple;
import std.string: format;
import std.exception: enforce;

import pyd.func_wrap;
import deimos.python.Python;
import util.multi_index;
import util.typeinfo;

// s/wrapped_class_object!T/PyObject/

/**
 * A useful check for whether a given class has been wrapped. Mainly used by
 * the conversion functions (see make_object.d), but possibly useful elsewhere.
 */
template is_wrapped(T) {
    alias pyd_references!T.Mapping Mapping;

    static if(!is(Mapping.TypeInfoType!T == T)) {
        alias is_wrapped!(Mapping.TypeInfoType!T) is_wrapped;
    }else{
        bool is_wrapped = false;
    }
}

/// _
// wrapped_class_type
template PydTypeObject(T) {
    alias pyd_references!T.Mapping Mapping;

    static if(!is(Mapping.TypeInfoType!T == T)) {
        alias PydTypeObject!(Mapping.TypeInfoType!T) PydTypeObject;
    }else{
        // The type object, an instance of PyType_Type
        __gshared PyTypeObject PydTypeObject;
    }
}

template IsRefParam(alias p) {
    enum IsRefParam = p == ParameterStorageClass.ref_ ||
        p == ParameterStorageClass.out_;
}

template FnHasRefParams(Fn) {
    alias anySatisfy!(IsRefParam, ParameterStorageClassTuple!(Fn))
        FnHasRefParams;
}

struct DFn_Py_Mapping {
    const(void)* d;
    PyObject* py;
    TypeInfo d_typeinfo;
    TypeInfo[] params_info;
    uint functionAttributes;
    string linkage;
    Constness constness;

    this(Fn)(Fn d, PyObject* py) if(isFunctionPointer!Fn) {
        static assert(!FnHasRefParams!Fn,
                "Pyd cannot handle ref or out parameters at this time");
        this.d = DKey(d);
        this.d_typeinfo = typeid(TypeInfoType!Fn);
        this.params_info = (cast(TypeInfo_Tuple) typeid(ParameterTypeTuple!Fn))
            .elements;
        this.py = py;
        this.functionAttributes = .functionAttributes!Fn;
        this.linkage = functionLinkage!Fn;
        this.constness = .constness!Fn;
    }

    template TypeInfoType(T) if(isFunctionPointer!T) {
        alias Unqual!(
                SetFunctionAttributes!(T, functionLinkage!T,
                    FunctionAttribute.none)) TypeInfoType;
    }

    public static const(void)* DKey(T)(T t)
        if(isFunctionPointer!T) {
            return cast(const(void)*) t;
        }

    public T FromKey(T)() {
        return cast(T) this.d;
    }
}

struct DDg_Py_Mapping {
    const(void)*[2] d;
    PyObject* py;
    TypeInfo d_typeinfo;
    TypeInfo[] params_info;
    uint functionAttributes;
    string linkage;
    Constness constness;

    this(Dg)(Dg d, PyObject* py) if(isDelegate!Dg) {
        static assert(!FnHasRefParams!Dg,
                "Pyd cannot handle ref or out parameters at this time");
        this.d = DKey(d);
        this.d_typeinfo = typeid(TypeInfoType!Dg);
        this.params_info = (cast(TypeInfo_Tuple) typeid(ParameterTypeTuple!Dg))
            .elements;
        this.py = py;
        this.functionAttributes = .functionAttributes!Dg;
        this.linkage = functionLinkage!Dg;
        this.constness = .constness!Dg;
    }

    template TypeInfoType(T) {
        alias Unqual!(
                SetFunctionAttributes!(T, functionLinkage!T,
                    FunctionAttribute.none)) TypeInfoType;
    }

    public static const(void)*[2] DKey(T)(T t)
        if(isDelegate!T) {
            typeof(return) key;
            key[0] = cast(const(void)*) t.ptr;
            key[1] = cast(const(void)*) t.funcptr;
            return key;
        }

    public T FromKey(T)() {
        T x;
        x.ptr = cast(void*) d[0];
        x.funcptr = cast(typeof(x.funcptr)) d[1];
        return x;
    }
}

struct DStruct_Py_Mapping {
    const(void)* d;
    PyObject* py;
    TypeInfo d_typeinfo;
    Constness constness;

    this(S)(S d, PyObject* py) if(isPointer!S &&
            is(PointerTarget!S == struct)) {
        this.d = DKey(d);
        this.d_typeinfo = typeid(TypeInfoType!S);
        this.py = py;
        this.constness = .constness!S;
    }

    template TypeInfoType(T) if(isPointer!T && is(PointerTarget!T == struct)) {
        alias Unqual!T TypeInfoType;
    }

    public static const(void)* DKey(T)(T t)
        if(isPointer!T && is(PointerTarget!T == struct)) {
            return cast(const(void)*) t;
    }

    public T FromKey(T)() {
        return cast(T) this.d;
    }
}

struct DClass_Py_Mapping {
    const(void)* d;
    PyObject* py;
    TypeInfo d_typeinfo;
    Constness constness;

    this(S)(S d, PyObject* py) if(is(S == class)) {
        this.d = cast(const(void)*) d;
        this.d_typeinfo = typeid(TypeInfoType!S);
        this.py = py;
        this.constness = .constness!S;
    }

    template TypeInfoType(T) if(is(T == class)) {
            alias Unqual!T TypeInfoType;
    }

    public static const(void)* DKey(T)(T t)
        if(is(T == class)) {
            return cast(const(void)*) t;
    }

    public T FromKey(T)() {
        return cast(T) this.d;
    }
}

/// A bidirectional mapping of a pyobject and the d object associated to it.
/// On the python side, these are weak references; we don't want to prevent
/// python from reclaiming objects it is finished with. As such, on the D side,
/// if you take PyObject*s out of here and store them for an extended time
/// elsewhere, be sure to increment the reference count.
/// On the D side, we have strong references, but that is incidental to the GC.
/// If you stick d objects not allocated with the GC, there will probably be
/// leaks.
/// We use malloc for the container's structure because we can't use the GC
/// inside a destructor and we need to use this container there.
template reference_container(Mapping) {
    static if(is(Mapping == DStruct_Py_Mapping)) {
        // See #104 for the reason for the hash functions below
        alias MultiIndexContainer!(
            Mapping,
            IndexedBy!(
                HashedNonUnique!("a.d", "cast(size_t) *cast(const void**) &a"), "d",
                HashedUnique!("a.py", "cast(size_t) *cast(const void**) &a"), "python"
                ),
            MallocAllocator, MutableView)
            Container;
    }else{
        alias MultiIndexContainer!(Mapping, IndexedBy!(
                    HashedUnique!("a.d"), "d",
                    HashedUnique!("a.py"), "python"),
                MallocAllocator, MutableView)
            Container;
    }
    Container _reference_container = null;

    @property reference_container() {
        if(!_reference_container) {
            _reference_container = Container.create();
            Py_AtExit(&clear);
        }
        return _reference_container;
    }

    extern(C) void clear() {
        if(_reference_container) {
            _reference_container.d.clear();
        }
    }
}

// A mapping of all GC references that are being held by Python.
template pyd_references(T) {
    static if(isDelegate!T) {
        alias DDg_Py_Mapping Mapping;
    }else static if (isFunctionPointer!T) {
        alias DFn_Py_Mapping Mapping;
    }else static if(isPointer!T && is(PointerTarget!T == struct)) {
        alias DStruct_Py_Mapping Mapping;
    }else static if (is(T == class)) {
        alias DClass_Py_Mapping Mapping;
    }else static assert(0, format("type %s cannot sent to pyd, because ??",
                T.stringof));
    alias reference_container!Mapping container;
}

void set_pyd_mapping(T) (PyObject* _self, T t) {
    alias pyd_references!T.Mapping Mapping;
    alias pyd_references!T.container container;

    Mapping mapping = Mapping(t, _self);
    auto py_index = container.python;
    auto range = py_index.equalRange(_self);
    if (range.empty) {
        auto count = py_index.insert(mapping);
        enforce(count != 0,
                format("could not add py reference %x for T=%s, t=%s",
                    _self, T.stringof,  Mapping.DKey(t)));
    }else{
        auto count = py_index.replace(PSR(range).front, mapping);
        enforce(count != 0,
                format("could not update py reference %x for T=%s, t=%s",
                    _self, T.stringof,  Mapping.DKey(t)));
    }
}

void remove_pyd_mapping(T)(PyObject* self) {
    import std.range;
    import std.stdio;
    alias pyd_references!T.Mapping Mapping;
    alias pyd_references!T.container container;

    auto py_index = container.python;
    auto range = py_index.equalRange(self);
    if(!range.empty) {
        py_index.remove(take(PSR(range),1));
    }
}

bool isConversionAddingFunctionAttributes(
        uint fromTypeFunctionAttributes,
        uint toTypeFunctionAttributes) {
    return (~(fromTypeFunctionAttributes | StrippedFunctionAttributes) & toTypeFunctionAttributes) != 0;
}


/**
 * Returns the object contained in a Python wrapped type.
 */
T get_d_reference(T) (PyObject* _self) {
    alias pyd_references!T.container container;
    alias pyd_references!T.Mapping Mapping;
    import thread = pyd.thread;

    thread.ensureAttached();

    enforce(is_wrapped!T,
            format(
                "Error extracting D object: Type %s is not wrapped.",
                typeid(T).toString()));
    enforce(_self !is null,
            "Error: trying to find D reference for null PyObject*!");

    auto py_index = container.python;
    auto range = py_index.equalRange(_self);

    enforce(!range.empty,
            "Error extracting D object: reference not found!");
    // don't cast away type!
    static if(is(T == class)) {
        auto tif = cast(TypeInfo_Class) range.front.d_typeinfo;
        auto t_info = typeid(Mapping.TypeInfoType!T);
        bool found = false;
        while(tif) {
            if(t_info == tif) {
                found = true;
                break;
            }
            tif = tif.base;
        }

        enforce(found,
            format(
                "Type mismatch extracting D object: found: %s, required: %s",
                range.front.d_typeinfo,
                typeid(Mapping.TypeInfoType!T)));

    }else{
        enforce(typeid(Mapping.TypeInfoType!T) == range.front.d_typeinfo,
            format(
                "Type mismatch extracting D object: found: %s, required: %s",
                range.front.d_typeinfo,
                typeid(Mapping.TypeInfoType!T)));
    }
    // don't cast away constness!
    // mutable => const, etc, okay
    enforce(constCompatible(range.front.constness, constness!T),
            format(
                "constness mismatch required: %s, found: %s",
                constness_ToString(constness!T),
                constness_ToString(range.front.constness)));
    static if(isFunctionPointer!T || isDelegate!T) {
        // don't cast away linkage!
        enforce(range.front.linkage == functionLinkage!T,
                format(
                    "trying to convert a extern(\"%s\") " ~
                    "%s to extern(\"%s\")",
                    range.front.linkage, (isDelegate!T ? "delegate":"function"),
                    functionLinkage!T));
        // losing function attributes is ok,
        // giving a function new ones, not so much
        enforce(
                !isConversionAddingFunctionAttributes(
                    range.front.functionAttributes, functionAttributes!T),
                format(
                    "trying to convert %s%s to %s",
                    SetFunctionAttributes!(T,
                        functionLinkage!T,
                        FunctionAttribute.none).stringof,
                    attrs_to_string(range.front.functionAttributes),
                    T.stringof));
    }

    return range.front.FromKey!T();
}

/// If the passed D reference has an existing Python object, return a borrowed
/// reference to it. Otherwise, return null.
PyObject_BorrowedRef* get_python_reference(T) (T t) {
    alias pyd_references!T.container container;
    alias pyd_references!T.Mapping Mapping;

    auto d_index = container.d;
    auto range = d_index.equalRange(Mapping.DKey(t));
    static if(is(Mapping == DStruct_Py_Mapping)) {
        findMatchingType!T(range);
    }
    if(range.empty) return null;
    return borrowed(range.front.py);
}

void findMatchingType(T, R)(ref R range) {
    while(!range.empty) {
        if(range.front.d_typeinfo == typeid(T)) {
            break;
        }
        range.popFront();
    }
}

/**
 * Returns a new Python object of a wrapped type.
 */
// WrapPyObject_FromTypeAndObject
// WrapPyObject_FromObject
PyObject* wrap_d_object(T)(T t, PyTypeObject* type = null) {
    if (!type) {
        type = &PydTypeObject!T;
    }
    if (is_wrapped!(T)) {
        // If this object is already wrapped, get the existing object.
        PyObject_BorrowedRef* obj_p = get_python_reference(t);
        if (obj_p) {
            return Py_INCREF(obj_p);
        }
        // Otherwise, allocate a new object
        PyObject* obj = type.tp_new(type, null, null);
        // Set the contained instance
        set_pyd_mapping(obj, t);
        return obj;
    } else {
        PyErr_SetString(PyExc_RuntimeError,
                (format("Type %s is not wrapped by Pyd.", typeid(T))).ptr);
        return null;
    }
}
