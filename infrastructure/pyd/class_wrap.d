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
module pyd.class_wrap;

import python;

import pyd.ctor_wrap;
import pyd.def;
import pyd.exception;
import pyd.func_wrap;
version (Pyd_with_StackThreads) {
    import pyd.iteration;
}
import pyd.make_object;
import pyd.op_wrap;
import pyd.lib_abstract :
    symbolnameof,
    prettytypeof,
    toString,
    ParameterTypeTuple,
    ReturnType,
    minArgs,
    objToStr
;

//import meta.Default;

PyTypeObject*[ClassInfo] wrapped_classes;

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
        0, /*tp_flags*/
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

// A mappnig of all class references that are being held by Python.
PyObject*[void*] wrapped_gc_objects;
// A mapping of all GC references that are being held by Python.
template wrapped_gc_references(dg_t) {
    PyObject*[dg_t] wrapped_gc_references;
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
        exception_catcher(delegate void() {
            WrapPyObject_SetObj(self, null);
            self.ob_type.tp_free(self);
        });
    }
}

template wrapped_repr(T) {
    alias wrapped_class_object!(T) wrap_object;
    /// The default repr method calls the class's toString.
    extern(C)
    PyObject* repr(PyObject* _self) {
        return exception_catcher({
            wrap_object* self = cast(wrap_object*)_self;
            char[] repr = objToStr(self.d_obj);
            return _py(repr);
        });
    }
}

// This template gets an alias to a property and derives the types of the
// getter form and the setter form. It requires that the getter form return the
// same type that the setter form accepts.
template property_parts(alias p) {
    // This may be either the getter or the setter
    alias typeof(&p) p_t;
    alias ParameterTypeTuple!(p_t) Info;
    // This means it's the getter
    static if (Info.length == 0) {
        alias p_t getter_type;
        // The setter may return void, or it may return the newly set attribute.
        alias typeof(p(ReturnType!(p_t).init)) function(ReturnType!(p_t)) setter_type;
    // This means it's the setter
    } else {
        alias p_t setter_type;
        alias Info[0] function() getter_type;
    }
}

///
template wrapped_get(T, alias Fn) {
    /// A generic wrapper around a "getter" property.
    extern(C)
    PyObject* func(PyObject* self, void* closure) {
        // method_wrap already catches exceptions
        return method_wrap!(T, Fn, property_parts!(Fn).getter_type).func(self, null);
    }
}

///
template wrapped_set(T, alias Fn) {
    /// A generic wrapper around a "setter" property.
    extern(C)
    int func(PyObject* self, PyObject* value, void* closure) {
        PyObject* temp_tuple = PyTuple_New(1);
        if (temp_tuple is null) return -1;
        scope(exit) Py_DECREF(temp_tuple);
        Py_INCREF(value);
        PyTuple_SetItem(temp_tuple, 0, value);
        PyObject* res = method_wrap!(T, Fn, property_parts!(Fn).setter_type).func(self, temp_tuple);
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

/**
 * This struct wraps a D class. Its member functions are the primary way of
 * wrapping the specific parts of the class.
 */
struct wrapped_class(T, char[] classname = symbolnameof!(T)) {
    static if (is(T == class)) pragma(msg, "wrapped_class: " ~ classname);
    static const char[] _name = classname;
    alias T wrapped_type;
    /**
     * Wraps a member function of the class.
     *
     * Params:
     * fn = The member function to wrap.
     * name = The name of the function as it will appear in Python.
     * fn_t = The type of the function. It is only useful to specify this
     *        if more than one function has the same name as this one.
     */
    static void def(alias fn, char[] name = symbolnameof!(fn), fn_t=typeof(&fn)) (char[] docstring="") {
        pragma(msg, "class.def: " ~ name);
        static PyMethodDef empty = { null, null, 0, null };
        alias wrapped_method_list!(T) list;
        list[length-1].ml_name = (name ~ "\0").ptr;
        list[length-1].ml_meth = &method_wrap!(T, fn, fn_t).func;
        list[length-1].ml_flags = METH_VARARGS;
        list[length-1].ml_doc = (docstring ~ "\0").ptr;
        list ~= empty;
        // It's possible that appending the empty item invalidated the
        // pointer in the type struct, so we renew it here.
        wrapped_class_type!(T).tp_methods = list.ptr;
    }

    /**
     * Wraps a static member function of the class. Identical to pyd.def.def
     */
    static void static_def(alias fn, char[] name = symbolnameof!(fn), fn_t=typeof(&fn), uint MIN_ARGS=minArgs!(fn)) (char[] docstring="") {
        pragma(msg, "class.static_def: " ~ name);
        static PyMethodDef empty = { null, null, 0, null };
        alias wrapped_method_list!(T) list;
        list[length-1].ml_name = (name ~ "\0").ptr;
        list[length-1].ml_meth = &function_wrap!(fn, MIN_ARGS, fn_t).func;
        list[length-1].ml_flags = METH_VARARGS | METH_STATIC;
        list[length-1].ml_doc = (docstring ~ "\0").ptr;
        list ~= empty;
        wrapped_class_type!(T).tp_methods = list;
    }

    /**
     * Wraps a property of the class.
     *
     * Params:
     * fn = The property to wrap.
     * name = The name of the property as it will appear in Python.
     * RO = Whether this is a read-only property.
     */
    static void prop(alias fn, char[] name = symbolnameof!(fn), bool RO=false) (char[] docstring="") {
        pragma(msg, "class.prop: " ~ name);
        static PyGetSetDef empty = { null, null, null, null, null };
        wrapped_prop_list!(T)[length-1].name = (name ~ "\0").ptr;
        wrapped_prop_list!(T)[length-1].get =
            &wrapped_get!(T, fn).func;
        static if (!RO) {
            wrapped_prop_list!(T)[length-1].set =
                &wrapped_set!(T, fn).func;
        }
        wrapped_prop_list!(T)[length-1].doc = (docstring ~ "\0").ptr;
        wrapped_prop_list!(T)[length-1].closure = null;
        wrapped_prop_list!(T) ~= empty;
        // It's possible that appending the empty item invalidated the
        // pointer in the type struct, so we renew it here.
        wrapped_class_type!(T).tp_getset =
            wrapped_prop_list!(T).ptr;
    }

    /**
     * Wraps the constructors of the class.
     *
     * This template takes a series of specializations of the ctor template
     * (see ctor_wrap.d), each of which describes a different constructor
     * that the class supports. The default constructor need not be
     * specified, and will always be available if the class supports it.
     *
     * Bugs:
     * This currently does not support having multiple constructors with
     * the same number of arguments.
     */
    static void init(C ...) () {
        wrapped_class_type!(T).tp_init =
            &wrapped_ctors!(T, C).init_func;
    }

    // Iteration wrapping support requires StackThreads
    version(Pyd_with_StackThreads) {

    /**
     * Allows selection of alternate opApply overloads. iter_t should be
     * the type of the delegate in the opApply function that the user wants
     * to be the default.
     */
    static void iter(iter_t) () {
        PydStackContext_Ready();
        wrapped_class_type!(T).tp_iter = &wrapped_iter!(T, T.opApply, int function(iter_t)).iter;
    }

    /**
     * Exposes alternate iteration methods, originally intended for use with
     * D's delegate-as-iterator features, as methods returning a Python
     * iterator.
     */
    static void alt_iter(alias fn, char[] name = symbolnameof!(fn), iter_t = funcDelegInfoT!(typeof(&fn)).Meta.ArgType!(0)) (char[] docstring="") {
        static PyMethodDef empty = { null, null, 0, null };
        alias wrapped_method_list!(T) list;
        PydStackContext_Ready();
        list[length-1].ml_name = name ~ "\0";
        list[length-1].ml_meth = cast(PyCFunction)&wrapped_iter!(T, fn, int function(iter_t)).iter;
        list[length-1].ml_flags = METH_VARARGS;
        list[length-1].ml_doc = (docstring ~ "\0").ptr;
        list ~= empty;
        // It's possible that appending the empty item invalidated the
        // pointer in the type struct, so we renew it here.
        wrapped_class_type!(T).tp_methods = list;
    }

    } /*Pyd_with_StackThreads*/
}

/**
 * Finalize the wrapping of the class. It is neccessary to call this after all
 * calls to the wrapped_class member functions.
 */
void finalize_class(CLS) (CLS cls, char[] docstring="", char[] modulename="") {
    alias CLS.wrapped_type T;
    alias wrapped_class_type!(T) type;
    const char[] name = CLS._name;
    static if (is(T == class)) {
        pragma(msg, "finalize_class: " ~ name);
    } else {
        pragma(msg, "finalize_struct: " ~ name);
    }
    pragma(msg, "finalize_class, T is " ~ prettytypeof!(T));
    
    assert(Pyd_Module_p(modulename) !is null, "Must initialize module before wrapping classes.");
    char[] module_name = toString(PyModule_GetName(Pyd_Module_p(modulename)));
    // Fill in missing values
    type.ob_type      = PyType_Type_p();
    type.tp_basicsize = (wrapped_class_object!(T)).sizeof;
    type.tp_doc       = (docstring ~ "\0").ptr;
    type.tp_flags     = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
    //type.tp_repr      = &wrapped_repr!(T).repr;
    type.tp_methods   = wrapped_method_list!(T).ptr;
    type.tp_name      = (module_name ~ "." ~ name ~ "\0").ptr;

    // Check for wrapped parent classes
    static if (is(T B == super)) {
        foreach (C; B) {
            static if (is(C == class) && !is(C == Object)) {
                if (is_wrapped!(C)) {
                    type.tp_base = &wrapped_class_type!(C);
                }
            }
        }
    }

    // Numerical operator overloads
    if (wrapped_class_as_number!(T) != PyNumberMethods.init) {
        type.tp_as_number = &wrapped_class_as_number!(T);
    }
    // Sequence operator overloads
    if (wrapped_class_as_sequence!(T) != PySequenceMethods.init) {
        type.tp_as_sequence = &wrapped_class_as_sequence!(T);
    }
    // Mapping operator overloads
    if (wrapped_class_as_mapping!(T) != PyMappingMethods.init) {
        type.tp_as_mapping = &wrapped_class_as_mapping!(T);
    }

    // Standard operator overloads
    // opApply
    version(Pyd_with_StackThreads) {
        static if (is(typeof(&T.opApply))) {
            if (type.tp_iter is null) {
                PydStackContext_Ready();
                type.tp_iter = &wrapped_iter!(T, T.opApply).iter;
            }
        }
    }
    // opCmp
    static if (is(typeof(&T.opCmp))) {
        type.tp_compare = &opcmp_wrap!(T).func;
    }
    // opCall
    static if (is(typeof(&T.opCall))) {
        type.tp_call = cast(ternaryfunc)&method_wrap!(T, T.opCall, typeof(&T.opCall)).func;
    }

    // If a ctor wasn't supplied, try the default.
    if (type.tp_init is null) {
        static if (is(T == class)) {
            type.tp_init = &wrapped_init!(T).init;
        } else {
            type.tp_init = &wrapped_struct_init!(T).init;
        }
    }
    if (PyType_Ready(&type) < 0) {
        // XXX: This will probably crash the interpreter, as it isn't normally
        // caught and translated.
        throw new Exception("Couldn't ready wrapped type!");
    }
    Py_INCREF(cast(PyObject*)&type);
    PyModule_AddObject(Pyd_Module_p(modulename), name.ptr, cast(PyObject*)&type);
    is_wrapped!(T) = true;
    static if (is(T == class)) {
        wrapped_classes[T.classinfo] = &type;
    }
}

template OverloadShim() {
    std.traits.ReturnType!(dg_t) get_overload(dg_t, T ...) (dg_t dg, char[] name, T t) {
        python.PyObject* _pyobj = wrapped_gc_objects[cast(void*)this];
        if (_pyobj.ob_type != &wrapped_class_type!(typeof(this))) {
            // If this object's type is not the wrapped class's type (that is,
            // if this object is actually a Python subclass of the wrapped
            // class), then call the Python object.
            python.PyObject* method = python.PyObject_GetAttrString(_pyobj, (name ~ "\0").ptr);
            if (method is null) handle_exception();
            dg_t pydg = PydCallable_AsDelegate!(dg_t)(method);
            python.Py_DECREF(method);
            return pydg(t);
        } else {
            return dg(t);
        }
    }
}

///////////////////////
// PYD API FUNCTIONS //
///////////////////////

// If the passed D reference has an existing Python object, return a borrowed
// reference to it. Otherwise, return null.
PyObject* get_existing_reference(T) (T t) {
    static if (is(T == class)) {
        PyObject** obj_p = cast(void*)t in wrapped_gc_objects;
        if (obj_p) return *obj_p;
        else return null;
    } else {
        PyObject** obj_p = t in wrapped_gc_references!(T);
        if (obj_p) return *obj_p;
        else return null;
    }
}

// Drop the passed D reference from the pool of held references.
void drop_reference(T) (T t) {
    static if (is(T == class)) {
        wrapped_gc_objects.remove(cast(void*)t);
    } else {
        wrapped_gc_references!(T).remove(t);
    }
}

// Add the passed D reference to the pool of held references.
void add_reference(T) (T t, PyObject* o) {
    static if (is(T == class)) {
        wrapped_gc_objects[cast(void*)t] = o;
    } else {
        wrapped_gc_references!(T)[t] = o;
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
        PyObject* obj_p = get_existing_reference(t);
        if (obj_p) {
            Py_INCREF(obj_p);
            return obj_p;
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
    if (!is_wrapped!(T) || self is null || !PyObject_TypeCheck(_self, &type)) {
        throw new Exception("Error extracting D object from Python object...");
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

