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
  Contains utilities for operating on generic python objects.
  */
module pyd.pydobject;

import deimos.python.Python;
import pyd.def;
import pyd.exception;
import pyd.make_object;
import std.exception: enforce;
import std.conv;
import util.conv;


/**
 * Wrapper class for a Python/C API PyObject.
 *
 * Nearly all of these member functions may throw a PythonException if the
 * underlying Python API raises a Python exception.
 *
 * Authors: $(LINK2 mailto:kirklin.mcdonald@gmail.com, Kirk McDonald)
 * Date: June 18, 2006
 * See_Also:
 *     $(LINK2 http://docs.python.org/api/api.html, The Python/C API)
 */
class PydObject {
protected:
    PyObject* m_ptr;
public:
    /**
     * Wrap an owned PyObject*.
     * This should typically only be used in conjuction with functions
     * in the deimos API that return PyObject* (they return new references).
     * Otherwise, wrap the incoming PyObject* with borrowed.
     */
    this(PyObject* o) {
        if (o is null) handle_exception();
        m_ptr = o;
    }

    /**
     * Own a borrowed PyObject* and wrap it.
     */
    this(Borrowed!PyObject* o) {
        if (o is null) handle_exception();
        // PydObject always owns its references
        m_ptr = Py_INCREF(o);
    }

    /// Constructs an instance of the Py_None PydObject.
    this() {
        m_ptr = Py_INCREF(Py_None());
    }

    /// Destructor. Calls Py_DECREF on PyObject reference.
    ~this() {
        if (m_ptr && !Py_Finalize_called) Py_DECREF(m_ptr);
        m_ptr = null;
    }

    version(Python_2_6_Or_Later) {
/**
  exposes a lowish-level wrapper of the new-style buffer interface

See_also:
<a href="http://docs.python.org/c-api/buffer.html">
Buffers and MemoryView Objects </a>
 */
        class BufferView {
            Py_buffer buffer;
            /// supports PyBUF_SIMPLE. $(BR)
            /// should always be true.
            bool has_simple = false;
            /// supports PyBUF_ND. $(BR)
            /// i.e. buffer supplies ndim, shape.
            bool has_nd = false;
            /// supports PyBUF_STRIDES. $(BR)
            /// i.e. buffer supplies strides.
            bool has_strides = false;
            /// supports PyBUF_INDIRECT. $(BR)
            /// i.e. buffer supplies suboffsets.
            bool has_indirect = false;
            /// supports PyBUF_C_CONTIGUOUS. $(BR)
            /// buffer is row-major.
            bool c_contiguous = false;
            /// supports PyBUF_F_CONTIGUOUS. $(BR)
            /// buffer is column-major
            bool fortran_contiguous = false;

            private @property m_ptr() {
                return this.outer.m_ptr;
            }

            /**
              construct buffer view. Probe for capabilities this object supports.
              */
            this() {
                enforce(PyObject_CheckBuffer(m_ptr));

                // probe buffer for capabilities
                if(PyObject_GetBuffer(m_ptr, &buffer, PyBUF_SIMPLE) == 0) {
                    has_simple = true;
                }else{
                    PyErr_Clear();
                }
                if(PyObject_GetBuffer(m_ptr, &buffer,
                            PyBUF_STRIDES|PyBUF_C_CONTIGUOUS) == 0) {
                    has_nd = true;
                    has_strides = true;
                    c_contiguous = true;
                }else{
                    PyErr_Clear();
                    if(PyObject_GetBuffer(m_ptr, &buffer,
                                PyBUF_STRIDES|PyBUF_F_CONTIGUOUS) == 0) {
                        has_nd = true;
                        has_strides = true;
                        fortran_contiguous = true;
                    }else{
                        PyErr_Clear();
                        if(PyObject_GetBuffer(m_ptr, &buffer,
                                    PyBUF_STRIDES) == 0) {
                            has_nd = true;
                            has_strides = true;
                        }else{
                            PyErr_Clear();
                            if(PyObject_GetBuffer(m_ptr, &buffer,
                                        PyBUF_ND) == 0) {
                                has_nd = true;
                            }else{
                                PyErr_Clear();
                            }
                        }
                    }
                }
                if(has_strides) {
                    if(PyObject_GetBuffer(m_ptr, &buffer, PyBUF_INDIRECT) == 0) {
                        has_indirect = true;
                    }else{
                        PyErr_Clear();
                    }
                }

                int flags = PyBUF_FORMAT |
                    (has_nd ? PyBUF_ND : 0) |
                    (has_strides ? PyBUF_STRIDES : 0) |
                    (c_contiguous ? PyBUF_C_CONTIGUOUS : 0) |
                    (fortran_contiguous ? PyBUF_F_CONTIGUOUS : 0) |
                    (has_indirect ? PyBUF_INDIRECT : 0);
                if(PyObject_GetBuffer(m_ptr, &buffer, flags) != 0) {
                    handle_exception();
                }
            }

            /**
              Construct buffer view. Don't probe for capabilities; assume
              object supports capabilities implied by flags.
              */
            this(int flags) {
                enforce(PyObject_CheckBuffer(m_ptr));
                has_simple = true;
                has_nd = (PyBUF_ND & flags) == PyBUF_ND;
                has_strides = (PyBUF_STRIDES & flags) == PyBUF_STRIDES;
                c_contiguous = (PyBUF_C_CONTIGUOUS & flags) == PyBUF_C_CONTIGUOUS;
                fortran_contiguous = (PyBUF_F_CONTIGUOUS & flags) == PyBUF_F_CONTIGUOUS;
                has_indirect = (PyBUF_INDIRECT & flags) == PyBUF_INDIRECT;

                if(PyObject_GetBuffer(m_ptr, &buffer, flags) != 0) {
                    handle_exception();
                }
            }

            /**
              Get the raw bytes of this buffer
              */
            @property ubyte[] buf() {
                enforce(has_simple);
                enforce(buffer.len >= 0);
                return (cast(ubyte*) buffer.buf)[0 .. buffer.len];
            }

            /// _
            @property bool readonly() {
                return cast(bool) buffer.readonly;
            }

/**
  Get the struct-style _format of the element type of this buffer.

See_Also:
<a href='http://docs.python.org/library/struct.html#struct-format-strings'>
Struct Format Strings </a>
*/

            @property string format() {
                return to!string(buffer.format);
            }

            /// Get number of dimensions of this buffer.
            @property int ndim() {
                if(!has_nd) return 0;
                return buffer.ndim;
            }

            /// _
            @property Py_ssize_t[] shape() {
                if(!has_nd || !buffer.shape) return [];
                return buffer.shape[0 .. ndim];
            }

            /// _
            @property Py_ssize_t[] strides() {
                if(!has_strides || !buffer.strides) return [];
                return buffer.strides[0 .. ndim];
            }
            /// _
            @property Py_ssize_t[] suboffsets() {
                if(!has_indirect || !buffer.suboffsets) return [];
                return buffer.suboffsets[0 .. ndim];
            }

            /// _
            @property itemsize() {
                return buffer.itemsize;
            }

            /// _
            T item(T)(Py_ssize_t[] indices...) {
                enforce(itemsize == T.sizeof);
                return *cast(T*) item_ptr(indices);
            }
            /// _
            void set_item(T)(T value, Py_ssize_t[] indices...) {
                import std.traits;
                enforce(itemsize == T.sizeof);
                auto ptr = cast(Unqual!T*) item_ptr(indices);
                *ptr = value;
            }

            void* item_ptr(Py_ssize_t[] indices...) {
                if(has_strides) enforce(indices.length == ndim);
                else enforce(indices.length == 1);
                if(has_strides) {
                    void* ptr = buffer.buf;
                    foreach(i, index; indices) {
                        ptr += strides[i] * index;
                        if(has_indirect && suboffsets != [] &&
                                suboffsets[i] >= 0) {
                            ptr += suboffsets[i];
                        }
                    }
                    return ptr;
                }else {
                    return buffer.buf+indices[0];
                }
            }
        }


        /**
          Get a BufferView of this object.
          Will fail if this does not support the new buffer interface.
          */
        BufferView buffer_view() {
            return new this.BufferView();
        }
        /**
          Get a BufferView of this object without probing for capabilities.
          Will fail if this does not support the new buffer interface.
          */
        BufferView buffer_view(int flags) {
            return new this.BufferView(flags);
        }
    }

    /**
     * Returns a borrowed reference to the PyObject.
     */
    @property Borrowed!PyObject* ptr() { return borrowed(m_ptr); }

    /*
     * Prints PyObject to a C FILE* object.
     * Params:
     *      fp = The file object to _print to. core.stdc.stdio.stdout by default.
     *      raw = If $(D_KEYWORD true), prints the "str" representation of the
     *            PydObject, and uses the "repr" otherwise. Defaults to
     *            $(D_KEYWORD false).
     * Bugs: This does not seem to work, raising an AccessViolation. Meh.
     *       Use toString.
     */
    /+
    void print(FILE* fp=stdout, bool raw=false) {
        if (PyObject_Print(m_ptr, fp, raw ? Py_PRINT_RAW : 0) == -1)
            handle_exception();
    }
    +/

    /// Equivalent to _hasattr(this, attr_name) in Python.
    bool hasattr(string attr_name) {
        return PyObject_HasAttrString(m_ptr, zcc(attr_name)) == 1;
    }

    /// Equivalent to _hasattr(this, attr_name) in Python.
    bool hasattr(PydObject attr_name) {
        return PyObject_HasAttr(m_ptr, attr_name.m_ptr) == 1;
    }

    /// Equivalent to _getattr(this, attr_name) in Python.
    PydObject getattr(string attr_name) {
        return new PydObject(PyObject_GetAttrString(m_ptr, zcc(attr_name)));
    }

    /// Equivalent to _getattr(this, attr_name) in Python.
    PydObject getattr(PydObject attr_name) {
        return new PydObject(PyObject_GetAttr(m_ptr, attr_name.m_ptr));
    }

    /**
     * Equivalent to _setattr(this, attr_name, v) in Python.
     */
    void setattr(string attr_name, PydObject v) {
        if (PyObject_SetAttrString(m_ptr, zcc(attr_name), v.m_ptr) == -1)
            handle_exception();
    }

    /**
     * Equivalent to _setattr(this, attr_name, v) in Python.
     */
    void setattr(PydObject attr_name, PydObject v) {
        if (PyObject_SetAttr(m_ptr, attr_name.m_ptr, v.m_ptr) == -1)
            handle_exception();
    }

    /**
     * Equivalent to del this.attr_name in Python.
     */
    void delattr(string attr_name) {
        if (PyObject_DelAttrString(m_ptr, zcc(attr_name)) == -1)
            handle_exception();
    }

    /**
     * Equivalent to del this.attr_name in Python.
     */
    void delattr(PydObject attr_name) {
        if (PyObject_DelAttr(m_ptr, attr_name.m_ptr) == -1)
            handle_exception();
    }

    /**
     * Exposes Python object comparison to D. Equivalent to cmp(this, rhs) in Python.
     */
    override int opCmp(Object o) {
        PydObject rhs = cast(PydObject) o;
        if (!rhs) return -1;
        version(Python_3_0_Or_Later) {
            int res = PyObject_RichCompareBool(m_ptr, rhs.m_ptr, Py_LT);
            if(res == -1) handle_exception();
            if(res == 1) return -1;
            res = PyObject_RichCompareBool(m_ptr, rhs.m_ptr, Py_EQ);
            if(res == -1) handle_exception();
            if(res == 1) return 0;
            return 1;
        }else{
            // This function happily maps exactly to opCmp
            // EMN: but goes away in python 3.
            int res = PyObject_Compare(m_ptr, rhs.m_ptr);
            // Check for possible error
            handle_exception();
            return res;
        }
    }

    /**
     * Exposes Python object equality check to D.
     */
    override bool opEquals(Object o) {
        PydObject rhs = cast(PydObject) o;
        if (!rhs) return false;
        int res = PyObject_RichCompareBool(m_ptr, rhs.m_ptr, Py_EQ);
        if(res == -1) handle_exception();
        return res == 1;
    }

    /// Equivalent to _repr(this) in Python.
    PydObject repr() {
        return new PydObject(PyObject_Repr(m_ptr));
    }

    /// Equivalent to _str(this) in Python.
    PydObject str() {
        return new PydObject(PyObject_Str(m_ptr));
    }
    /// Allows use of PydObject in writeln via %s
    override string toString() {
        return python_to_d!(string)(m_ptr);
    }

    version(Python_3_0_Or_Later) {
    }else{
        /// Equivalent to _unicode(this) in Python.
        PydObject unicode() {
            return new PydObject(PyObject_Unicode(m_ptr));
        }
    }

    /// Equivalent to _bytes(this) in Python.
    PydObject bytes() {
        return new PydObject(PyObject_Bytes(m_ptr));
    }

    /// Equivalent to isinstance(this, cls) in Python.
    bool isinstance(PydObject cls) {
        int res = PyObject_IsInstance(m_ptr, cls.m_ptr);
        if (res == -1) handle_exception();
        return res == 1;
    }

    /// Equivalent to issubclass(this, cls) in Python. Only works if this is a class.
    bool issubclass(PydObject cls) {
        int res = PyObject_IsSubclass(m_ptr, cls.m_ptr);
        if (res == -1) handle_exception();
        return res == 1;
    }

    /// Equivalent to _callable(this) in Python.
    bool callable() {
        return PyCallable_Check(m_ptr) == 1;
    }

    /**
     * Calls the PydObject with args.
     * Params:
     *      args = Should be a tuple of the arguments to pass. Omit to
     *             call with no arguments.
     * Returns: Whatever this function object returns.
     */
    PydObject unpack_call(PydObject args=null) {
        return new PydObject(PyObject_CallObject(m_ptr, args is null ? null : args.m_ptr));
    }

    /**
     * Calls the PydObject with positional and keyword arguments.
     * Params:
     *      args = Positional arguments. Should be a tuple. Pass an empty
     *             tuple for no positional arguments.
     *      kw = Keyword arguments. Should be a dict.
     * Returns: Whatever this function object returns.
     */
    PydObject unpack_call(PydObject args, PydObject kw) {
        return new PydObject(PyObject_Call(m_ptr, args.m_ptr, kw.m_ptr));
    }

    /**
     * Calls the PydObject with any convertible D items.
     */
    PydObject opCall(T ...) (T t) {
        PyObject* tuple = PyTuple_FromItems(t);
        if (tuple is null) handle_exception();
        PyObject* result = PyObject_CallObject(m_ptr, tuple);
        Py_DECREF(tuple);
        if (result is null) handle_exception();
        return new PydObject(result);
    }

    /**
     * Calls the PydObject method with args.
     * Params:
     *      name = name of method to call
     *      args = Should be a tuple of the arguments to pass. Omit to
     *             call with no arguments.
     * Returns: Whatever this object's method returns.
     */
    PydObject method_unpack(string name, PydObject args=null) {
        // Get the method PydObject
        PyObject* m = PyObject_GetAttrString(m_ptr, zcc(name));
        PyObject* result;
        // If this method doesn't exist (or other error), throw exception
        if (m is null) handle_exception();
        // Call the method, and decrement the refcounts on the temporaries.
        result = PyObject_CallObject(m, args is null ? null : args.m_ptr);
        Py_DECREF(m);
        // Return the result.
        return new PydObject(result);
    }

    /**
     * Calls the PydObject method with positional and keyword arguments.
     * Params:
     *      name = name of method to call.
     *      args = Positional arguments. Should be a tuple. Pass an empty
     *             tuple for no positional arguments.
     *      kw = Keyword arguments. Should be a dict.
     * Returns: Whatever this object's method returns.
     */
    PydObject method_unpack(string name, PydObject args, PydObject kw) {
        // Get the method PydObject
        PyObject* m = PyObject_GetAttrString(m_ptr, zcc(name));
        PyObject* result;
        // If this method doesn't exist (or other error), throw exception.
        if (m is null) handle_exception();
        // Call the method, and decrement the refcounts on the temporaries.
        result = PyObject_Call(m, args.m_ptr, kw.m_ptr);
        Py_DECREF(m);
        // Return the result.
        return new PydObject(result);
    }

    /**
     * Calls a method of the object with any convertible D items.
     */
    PydObject method(T ...) (string name, T t) {
        PyObject* mthd = PyObject_GetAttrString(m_ptr, zcc(name));
        if (mthd is null) handle_exception();
        PyObject* tuple = PyTuple_FromItems(t);
        if (tuple is null) {
            Py_DECREF(mthd);
            handle_exception();
        }
        PyObject* result = PyObject_CallObject(mthd, tuple);
        Py_DECREF(mthd);
        Py_DECREF(tuple);
        if (result is null) handle_exception();
        return new PydObject(result);
    }

    /// Equivalent to _hash(this) in Python.
    hash_t hash() {
        hash_t res = PyObject_Hash(m_ptr);
        if (res == -1) handle_exception();
        return res;
    }

    /// Convert this object to instance of T.
    T to_d(T)() {
        return python_to_d!(T)(m_ptr);
    }

    /// Equivalent to "_not this" in Python.
    bool not() {
        int res = PyObject_Not(m_ptr);
        if (res == -1) handle_exception();
        return res == 1;
    }

    /**
     * Gets the _type of this PydObject. Equivalent to _type(this) in Python.
     * Returns: The _type PydObject of this PydObject.
     */
    PydObject type() {
        return new PydObject(PyObject_Type(m_ptr));
    }

    /**
     * The _length of this PydObject. Equivalent to _len(this) in Python.
     */
    Py_ssize_t length() {
        Py_ssize_t res = PyObject_Length(m_ptr);
        if (res == -1) handle_exception();
        return res;
    }
    /// Equivalent to length()
    Py_ssize_t size() { return length(); }

    /// Equivalent to _dir(this) in Python.
    PydObject dir() {
        return new PydObject(PyObject_Dir(m_ptr));
    }

    //----------
    // Indexing
    //----------
    /// Equivalent to o[_key] in Python.
    PydObject opIndex(PydObject key) {
        return new PydObject(PyObject_GetItem(m_ptr, key.m_ptr));
    }
    /**
     * Equivalent to o['_key'] in Python; usually only makes sense for
     * mappings.
     */
    PydObject opIndex(string key) {
        // wtf? PyMapping_GetItemString fails on dicts
        if(PyDict_Check(m_ptr)) {
            return new PydObject(PyDict_GetItemString(m_ptr, zc(key)));
        }else{
            return new PydObject(PyMapping_GetItemString(m_ptr, zc(key)));
        }
    }
    /// Equivalent to o[_i] in Python; usually only makes sense for sequences.
    PydObject opIndex(Py_ssize_t i) {
        return new PydObject(PySequence_GetItem(m_ptr, i));
    }

    /// Equivalent to o[_key] = _value in Python.
    void opIndexAssign(T,S)(T value, S key) {
        static if (is(T == PydObject)) {
            alias value v;
        }else{
            auto v = py(value);
        }
        static if (is(S : int)) {
            if (PySequence_SetItem(m_ptr, key, v.m_ptr) == -1)
                handle_exception();
            return;
        }else static if (is(S == PydObject)) {
            alias key k;
        }else{
            auto k = py(key);
        }

        static if(!(is(S : int))) {
            if (PyObject_SetItem(m_ptr, k.m_ptr, v.m_ptr) == -1)
                handle_exception();
        }
    }
    /// Equivalent to del o[_key] in Python.
    void del_item(PydObject key) {
        if (PyObject_DelItem(m_ptr, key.m_ptr) == -1)
            handle_exception();
    }
    /**
     * Equivalent to del o['_key'] in Python. Usually only makes sense for
     * mappings.
     */
    void del_item(string key) {
        if (PyMapping_DelItemString(m_ptr, zc(key)) == -1)
            handle_exception();
    }
    /**
     * Equivalent to del o[_i] in Python. Usually only makes sense for
     * sequences.
     */
    void del_item(int i) {
        if (PySequence_DelItem(m_ptr, i) == -1)
            handle_exception();
    }

    //---------
    // Slicing
    //---------
    /// Equivalent to o[_i1:_i2] in Python.
    PydObject opSlice(Py_ssize_t i1, Py_ssize_t i2) {
        return new PydObject(PySequence_GetSlice(m_ptr, i1, i2));
    }
    /// Equivalent to o[:] in Python.
    PydObject opSlice() {
        return this.opSlice(0, this.length());
    }
    /// Equivalent to o[_i1:_i2] = _v in Python.
    void opSliceAssign(PydObject v, Py_ssize_t i1, Py_ssize_t i2) {
        if (PySequence_SetSlice(m_ptr, i1, i1, v.m_ptr) == -1)
            handle_exception();
    }
    /// Equivalent to o[:] = _v in Python.
    void opSliceAssign(PydObject v) {
        this.opSliceAssign(v, 0, this.length());
    }
    /// Equivalent to del o[_i1:_i2] in Python.
    void del_slice(Py_ssize_t i1, Py_ssize_t i2) {
        if (PySequence_DelSlice(m_ptr, i1, i2) == -1)
            handle_exception();
    }
    /// Equivalent to del o[:] in Python.
    void del_slice() {
        this.del_slice(0, this.length());
    }

    //-----------
    // Iteration
    //-----------

    /**
     * Iterates over the items in a collection, be they the items in a
     * sequence, keys in a dictionary, or some other iteration defined for the
     * PydObject's type.
     */
    int opApply(int delegate(ref PydObject) dg) {
        PyObject* iterator = PyObject_GetIter(m_ptr);
        PyObject* item;
        int result = 0;
        PydObject o;

        if (iterator == null) {
            handle_exception();
        }

        item = PyIter_Next(iterator);
        while (item) {
            o = new PydObject(item);
            result = dg(o);
            Py_DECREF(item);
            if (result) break;
            item = PyIter_Next(iterator);
        }
        Py_DECREF(iterator);

        // Just in case an exception occured
        handle_exception();

        return result;
    }

    /**
     * Iterate over (key, value) pairs in a dictionary. If the PydObject is not
     * a dict, this simply does nothing. (It iterates over no items.) You
     * should not attempt to modify the dictionary while iterating through it,
     * with the exception of modifying values. Adding or removing items while
     * iterating through it is an especially bad idea.
     */
    int opApply(int delegate(ref PydObject, ref PydObject) dg) {
        Borrowed!PyObject* key, value;
        Py_ssize_t pos = 0;
        int result = 0;
        PydObject k, v;

        while (PyDict_Next(m_ptr, &pos, &key, &value)) {
            k = new PydObject(key);
            v = new PydObject(value);
            result = dg(k, v);
            if (result) break;
        }

        return result;
    }

    //------------
    // Arithmetic
    //------------
    /// Forwards to appropriate Python binary operator overload.
    ///
    /// Note the result of / in python 3 (and python 2, if CO_FUTURE_DIVISION
    /// is set) is interpreted as "true division", otherwise it is integer
    /// division for integer arguments.
    ///
    /// See_Also:
    /// <a href="http://www.python.org/dev/peps/pep-0238/"> PEP 238 </a>
    PydObject opBinary(string op, T)(T o) if(op != "in") {
        static if((is(T : int) || is(T == PydObject)) && op == "*") {
            if(PySequence_Check(m_ptr)) {
                static if(is(T == PydObject)) {
                    int j = python_to_d!int(o.m_ptr);
                }else{
                    alias o j;
                }
                return new PydObject(PySequence_Repeat(m_ptr, j));
            }
        }
        static if (!is(T == PydObject)) {
            PydObject rhs = py(o);
        }else{
            alias o rhs;
        }
        static if(op == "+") {
            return new PydObject(PyNumber_Add(m_ptr, rhs.m_ptr));
        }else static if(op == "-") {
            return new PydObject(PyNumber_Subtract(m_ptr, rhs.m_ptr));
        }else static if(op == "*") {
            return new PydObject(PyNumber_Multiply(m_ptr, rhs.m_ptr));
        }else static if(op == "/") {
            version(Python_3_0_Or_Later) {
                return new PydObject(PyNumber_TrueDivide(m_ptr, rhs.m_ptr));
            }else{
                return new PydObject(PyNumber_Divide(m_ptr, rhs.m_ptr));
            }
        }else static if(op == "%") {
            return new PydObject(PyNumber_Remainder(m_ptr, rhs.m_ptr));
        }else static if(op == "^^") {
            return new PydObject(PyNumber_Power(m_ptr, rhs.m_ptr, Py_INCREF(Py_None())));
        }else static if(op == "<<") {
            return new PydObject(PyNumber_Lshift(m_ptr, rhs.m_ptr));
        }else static if(op == ">>") {
            return new PydObject(PyNumber_Rshift(m_ptr, rhs.m_ptr));
        }else static if(op == "&") {
            return new PydObject(PyNumber_And(m_ptr, rhs.m_ptr));
        }else static if(op == "^") {
            return new PydObject(PyNumber_Xor(m_ptr, rhs.m_ptr));
        }else static if(op == "|") {
            return new PydObject(PyNumber_Or(m_ptr, rhs.m_ptr));
        }else static if(op == "~") {
            return new PydObject(PySequence_Concat(m_ptr, rhs.m_ptr));
        }else static assert(false, "operator " ~ op ~" not supported");
    }

    /// Forwards to appropriate Python unary operator overload.
    PydObject opUnary(string op)() {
        static if(op == "+") {
            return new PydObject(PyNumber_Positive(m_ptr));
        }else static if(op == "-") {
            return new PydObject(PyNumber_Negative(m_ptr));
        }else static if(op == "~") {
            return new PydObject(PyNumber_Invert(m_ptr));
        }
    }
    /// Forwards to PyNumber_FloorDivide for numbers, and method otherwise.
    /// See_Also:
    /// <a href="http://docs.python.org/c-api/number.html#PyNumber_FloorDivide">
    /// PyNumber_FloorDivide </a>
    PydObject floor_div(PydObject o) {
        if(PyNumber_Check(m_ptr)) {
            return new PydObject(PyNumber_FloorDivide(m_ptr, o.m_ptr));
        }else{
            return this.method("floor_div", o);
        }
    }
    /// Forwards to PyNumber_TrueDivide for numbers, and method otherwise.
    /// See_Also:
    /// <a href="http://docs.python.org/c-api/number.html#PyNumber_TrueDivide">
    /// PyNumber_TrueDivide </a>
    PydObject true_div(PydObject o) {
        if(PyNumber_Check(m_ptr)) {
            return new PydObject(PyNumber_TrueDivide(m_ptr, o.m_ptr));
        }else{
            return this.method("true_div", o);
        }
    }
    /// Equivalent to _divmod(this, o) for numbers, and this._divmod(o)
    /// otherwise.
    /// See_Also:
    /// <a href="http://docs.python.org/library/functions.html#divmod">
    /// _divmod </a>
    PydObject divmod(PydObject o) {
        if(PyNumber_Check(m_ptr)) {
            return new PydObject(PyNumber_Divmod(m_ptr, o.m_ptr));
        }else{
            return this.method("divmod", o);
        }
    }
    /// Equivalent to _pow(this, exp, mod) for numbers, and this._pow(exp,mod)
    /// otherwise.
    /// See_Also:
    /// <a href="http://docs.python.org/library/functions.html#pow">
    /// _pow </a>
    PydObject pow(PydObject exp, PydObject mod=null) {
        if(PyNumber_Check(m_ptr)) {
            return new PydObject(PyNumber_Power(m_ptr, exp.m_ptr, (mod is null) ? null : mod.m_ptr));
        }else{
            return this.method("pow", exp, mod);
        }
    }
    /// Equivalent to _abs(this) for numbers, and this._abs()
    /// otherwise.
    /// See_Also:
    /// <a href="http://docs.python.org/library/functions.html#abs">
    /// _abs </a>
    PydObject abs() {
        if(PyNumber_Check(m_ptr)) {
            return new PydObject(PyNumber_Absolute(m_ptr));
        }else{
            return this.method("abs");
        }
    }

    //---------------------
    // In-place arithmetic
    //---------------------
    /// Forwards to appropriate python in-place operator overload.
    PydObject opOpAssign(string op, T)(T o) {
        static if((is(T : int) || is(T == PydObject)) && op == "*") {
            if(PySequence_Check(m_ptr)) {
                static if(is(T == PydObject)) {
                    int j = python_to_d!int(o.m_ptr);
                }else{
                    alias o j;
                }

                PyObject* result = PySequence_InPlaceRepeat(m_ptr, j);
                if (result is null) handle_exception();
                Py_DECREF(m_ptr);
                m_ptr = result;
                return this;
            }
        }
        static if (!is(T == PydObject)) {
            PydObject rhs = py(o);
        }else{
            alias o rhs;
        }
        static if(op == "+") {
            alias PyNumber_InPlaceAdd Op;
        }else static if(op == "-") {
            alias PyNumber_InPlaceSubtract Op;
        }else static if(op == "*") {
            alias PyNumber_InPlaceMultiply Op;
        }else static if(op == "/") {
            version(Python_3_0_Or_Later) {
                alias PyNumber_InPlaceTrueDivide Op;
            }else{
                alias PyNumber_InPlaceDivide Op;
            }
        }else static if(op == "%") {
            alias PyNumber_InPlaceRemainder Op;
        }else static if(op == "^^") {
            alias PyNumber_InPlacePower Op;
        }else static if(op == "<<") {
            alias PyNumber_InPlaceLshift Op;
        }else static if(op == ">>") {
            alias PyNumber_InPlaceRshift Op;
        }else static if(op == "&") {
            alias PyNumber_InPlaceAnd Op;
        }else static if(op == "^") {
            alias PyNumber_InPlaceXor Op;
        }else static if(op == "|") {
            alias PyNumber_InPlaceOr Op;
        }else static if(op == "~") {
            alias PySequence_InPlaceConcat Op;
        }else static assert(false, "operator " ~ op ~" not supported");

        //EMN: not seeming to be working the way we want it
        /+
        if (PyType_HasFeature(m_ptr.ob_type, Py_TPFLAGS_HAVE_INPLACEOPS)) {
            Op(m_ptr, count);
            handle_exception();
        } else {
        +/
            PyObject* result = Op(m_ptr, rhs.m_ptr);
            if (result is null) handle_exception();
            Py_DECREF(m_ptr);
            m_ptr = result;
        //}
        return this;
    }

    //-----------------
    // Type conversion
    //-----------------
    version(Python_3_0_Or_Later) {
    }else{
        /// Converts any Python number to int.
        PydObject as_int() {
            return new PydObject(PyNumber_Int(m_ptr));
        }
    }
    /// Converts any Python number to long.
    PydObject as_long() {
        return new PydObject(PyNumber_Long(m_ptr));
    }
    /// Converts any Python number to float.
    PydObject as_float() {
        return new PydObject(PyNumber_Float(m_ptr));
    }

    //------------------
    // Sequence methods
    //------------------

    // Sequence concatenation
    // see opBinary, opOpAssign

    /// Equivalent to 'this.count(v)' in Python.
    Py_ssize_t count(PydObject v) {
        if(PySequence_Check(m_ptr)) {
            Py_ssize_t result = PySequence_Count(m_ptr, v.m_ptr);
            if (result == -1) handle_exception();
            return result;
        }else {
            return this.method("count", v).to_d!Py_ssize_t();
        }
    }
    /// Equivalent to 'this.index(v)' in Python
    Py_ssize_t index(PydObject v) {
        if(PySequence_Check(m_ptr)) {
            Py_ssize_t result = PySequence_Index(m_ptr, v.m_ptr);
            if (result == -1) handle_exception();
            return result;
        }else {
            return this.method("index", v).to_d!Py_ssize_t();
        }
    }
    /// Converts any iterable PydObject to a list
    PydObject as_list() {
        return new PydObject(PySequence_List(m_ptr));
    }
    /// Converts any iterable PydObject to a tuple
    PydObject as_tuple() {
        return new PydObject(PySequence_Tuple(m_ptr));
    }
    // Added by list:
    /// Equivalent to 'this._insert(i,item)' in python.
    void insert(int i, PydObject item) {
        if(PyList_Check(m_ptr)) {
            if(PyList_Insert(m_ptr, i, item.m_ptr) == -1) {
                handle_exception();
            }
        }else{
            this.method("insert")(i,item);
        }
    }
    // Added by list:
    /// Equivalent to 'this._append(item)' in python.
    void append(PydObject item) {
        if(PyList_Check(m_ptr)) {
            if(PyList_Append(m_ptr, item.m_ptr) == -1) {
                handle_exception();
            }
        }else{
            this.method("append", item);
        }
    }
    // Added by list:
    /// Equivalent to 'this._sort()' in Python.
    void sort() {
        if(PyList_Check(m_ptr)) {
            if(PyList_Sort(m_ptr) == -1) {
                handle_exception();
            }
        }else{
            this.method("sort");
        }
    }
    // Added by list:
    /// Equivalent to 'this.reverse()' in Python.
    void reverse() {
        if(PyList_Check(m_ptr)) {
            if(PyList_Reverse(m_ptr) == -1) {
                handle_exception();
            }
        }else{
            this.method("reverse");
        }
    }

    //-----------------
    // Mapping methods
    //-----------------
    /// Equivalent to "v in this" in Python.
    bool opBinaryRight(string op,T)(T v) if(op == "in" && is(T == PydObject)){
        int result = PySequence_Contains(m_ptr, v.m_ptr);
        if (result == -1) handle_exception();
        return result == 1;
    }
    /// ditto
    bool opBinaryRight(string op,T)(T key) if(op == "in" && is(T == string)){
        if(!PySequence_Check(m_ptr) && (PyDict_Check(m_ptr) || PyMapping_Check(m_ptr))) {
            return this.has_key(key);
        }else{
            PydObject v = py(key);
            int result = PySequence_Contains(m_ptr, v.m_ptr);
            if (result == -1) handle_exception();
            return result == 1;
        }
    }
    /// Equivalent to 'key in this' in Python.
    bool has_key(string key) {
        int result = PyMapping_HasKeyString(m_ptr, zc(key));
        if (result == -1) handle_exception();
        return result == 1;
    }
    /// ditto
    bool has_key(PydObject key) {
        return this.opBinaryRight!("in",PydObject)(key);
    }
    /// Equivalent to 'this._keys()' in Python.
    PydObject keys() {
        // wtf? PyMapping_Keys fails on dicts
        if(PyDict_Check(m_ptr)) {
            return new PydObject(PyDict_Keys(m_ptr));
        }else if(PyMapping_Keys(m_ptr)) {
            return new PydObject(PyMapping_Keys(m_ptr));
        }else{
            return this.method("keys");
        }
    }
    /// Equivalent to 'this._values()' in Python.
    PydObject values() {
        // wtf? PyMapping_Values fails on dicts
        if(PyDict_Check(m_ptr)) {
            return new PydObject(PyDict_Values(m_ptr));
        }else if(PyMapping_Check(m_ptr)) {
            return new PydObject(PyMapping_Values(m_ptr));
        }else{
            return this.method("values");
        }
    }
    /// Equivalent to 'this._items()' in Python.
    PydObject items() {
        // wtf? PyMapping_Items fails on dicts
        if(PyDict_Check(m_ptr)) {
            return new PydObject(PyDict_Items(m_ptr));
        }else if(PyMapping_Check(m_ptr)) {
            return new PydObject(PyMapping_Items(m_ptr));
        }else {
            return this.method("items");
        }
    }

    // Added by dict
    /// For dicts, wraps PyDict_Clear. Otherwise forwards to method.
    /// See_Also:
    /// <a href="http://docs.python.org/c-api/dict.html#PyDict_Clear">
    /// PyDict_Clear </a>
    void clear() {
        if(PyDict_Check(m_ptr)) {
            PyDict_Clear(m_ptr);
        }else{
            this.method("clear");
        }
    }

    // Added by dict
    /// For dicts, wraps PyDict_Copy. Otherwise forwards to method.
    /// See_Also:
    /// <a href="http://docs.python.org/c-api/dict.html#PyDict_Copy">
    /// PyDict_Copy </a>
    PydObject copy() {
        if(PyDict_Check(m_ptr)) {
            return new PydObject(PyDict_Copy(m_ptr));
        }else{
            return this.method("copy");
        }
    }

    // Added by dict
    /// For dicts, wraps PyDict_Merge. Otherwise forwards to method.
    /// See_Also:
    /// <a href="http://docs.python.org/c-api/dict.html#PyDict_Merge">
    /// PyDict_Merge </a>
    void merge(PydObject o, bool override_=true) {
        if(PyDict_Check(m_ptr)) {
            int res = PyDict_Merge(m_ptr,o.m_ptr,override_);
            if(res == -1) handle_exception();
        }else{
            this.method("merge", o, override_);
        }
    }


    // Added by module
    /// For module objects, wraps PyModule_GetDict (essentially a dir()
    /// operation in Python). Otherwise forwards to method.
    /// See_Also:
    /// <a href="http://docs.python.org/c-api/module.html#PyModule_GetDict">
    /// PyModule_GetDict </a>
    PydObject getdict() {
        if(PyModule_Check(m_ptr)) {
            return new PydObject(PyModule_GetDict(m_ptr));
        }else{
            return this.method("getdict");
        }
    }

    /// Forwards to getattr
    @property auto opDispatch(string nom)() if(nom != "popFront") {
        return this.getattr(nom);
    }
    /// Forwards to setattr
    @property void opDispatch(string nom, T)(T val) {
        static if(is(T == PydObject)) {
            alias val value;
        }else{
            auto value = py(val);
        }
        this.setattr(nom,value);
    }
    /// Forwards to method.
    auto opDispatch(string nom, T...)(T ts) if(nom != "popFront") {
        return this.getattr(nom).opCall(ts);
    }

}

/// Convenience wrapper for Py_None
@property PydObject None() {
    static PydObject _None;
    enforce(Py_IsInitialized());
    if(!_None) _None = new PydObject();
    return _None;
}

/**
Wrap a python iterator in a D input range.
Params:
E = element type of this range. converts elements of iterator to E.
*/
struct PydInputRange(E = PydObject) {
    PyObject* iter;
    PyObject* _front = null;
    /// _
    this(PyObject* obj) {
        iter = PyObject_GetIter(obj);
        if (iter is null) {
            handle_exception();
        }
        popFront();
    }
    /// _
    this(Borrowed!PyObject* bobj) {
        PyObject* obj = Py_INCREF(bobj);
        iter = PyObject_GetIter(obj);
        if (iter is null) {
            handle_exception();
        }
        popFront();
    }
    this(this) {
        Py_INCREF(iter);
    }
    ~this() {
        Py_XDECREF(iter);
    }

    /// _
    @property front() {
        return python_to_d!E(_front);
    }

    /// _
    @property empty() {
        return _front is null;
    }

    /// _
    void popFront() {
        Py_XDECREF(_front);
        _front = PyIter_Next(iter);
    }

}

