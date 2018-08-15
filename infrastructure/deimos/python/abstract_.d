/**
  Mirror abstract.h

See_Also:
<a href="http://docs.python.org/c-api/abstract.html"> Abstract Objects Layer</a>
  */
module deimos.python.abstract_;

import deimos.python.pyport;
import deimos.python.object;

extern(C):

// D translations of C macros:
/// _
int PyObject_DelAttrString()(PyObject* o, const(char) *a) {
    return PyObject_SetAttrString(o, a, null);
}
/// _
int PyObject_DelAttr()(PyObject* o, PyObject* a) {
    return PyObject_SetAttr(o, a, null);
}

version(Python_3_0_Or_Later) {
}else{
/// _
int PyObject_Cmp(PyObject* o1, PyObject* o2, int *result);
}

//-//////////////////////////////////////////////////////////////////////////
// CALLABLES
//-//////////////////////////////////////////////////////////////////////////

/// _
PyObject* PyObject_Call(PyObject* callable_object, PyObject* args, PyObject* kw);
/// _
PyObject* PyObject_CallObject(PyObject* callable_object, PyObject* args);
/// _
PyObject* PyObject_CallFunction(PyObject* callable_object, char* format, ...);
/// _
PyObject* PyObject_CallMethod(PyObject* o, const(char)* m, const(char)* format, ...);
/// _
PyObject* PyObject_CallFunctionObjArgs(PyObject* callable, ...);
/// _
PyObject* PyObject_CallMethodObjArgs(PyObject* o,PyObject* m, ...);

//-//////////////////////////////////////////////////////////////////////////
// GENERIC
//-//////////////////////////////////////////////////////////////////////////
/// _
PyObject* PyObject_Type(PyObject* o);

//-//////////////////////////////////////////////////////////////////////////
// CONTAINERS
//-//////////////////////////////////////////////////////////////////////////

/// _
Py_ssize_t PyObject_Length(PyObject* o);
/// _
alias PyObject_Length PyObject_Size;

/** The length hint function returns a non-negative value from o.__len__()
   or o.__length_hint__().  If those methods aren't found or return a negative
   value, then the defaultvalue is returned.  If one of the calls fails,
   this function returns -1.
*/
version(Python_2_6_Or_Later){
    Py_ssize_t _PyObject_LengthHint(PyObject*, Py_ssize_t);
}else version(Python_2_5_Or_Later){
    Py_ssize_t _PyObject_LengthHint(PyObject*);
}

/// _
PyObject* PyObject_GetItem(PyObject* o, PyObject* key);
/// _
int PyObject_SetItem(PyObject* o, PyObject* key, PyObject* v);
/// _
int PyObject_DelItemString(PyObject* o, char* key);
/// _
int PyObject_DelItem(PyObject* o, PyObject* key);
/// _

int PyObject_AsCharBuffer(PyObject* obj, const(char)** buffer,
        Py_ssize_t* buffer_len);
/// _
int PyObject_CheckReadBuffer(PyObject* obj);
/// _
int PyObject_AsReadBuffer(PyObject* obj, void** buffer, Py_ssize_t* buffer_len);
/// _
int PyObject_AsWriteBuffer(PyObject* obj, void** buffer, Py_ssize_t* buffer_len);

version(Python_2_6_Or_Later){
    /* new buffer API */

    /** Return 1 if the getbuffer function is available, otherwise
       return 0 */
    int PyObject_CheckBuffer()(PyObject* obj){
        version(Python_3_0_Or_Later) {
            return (obj.ob_type.tp_as_buffer !is null) &&
                (obj.ob_type.tp_as_buffer.bf_getbuffer !is null);
        }else{
            return (obj.ob_type.tp_as_buffer !is null) &&
                PyType_HasFeature(obj.ob_type, Py_TPFLAGS_HAVE_NEWBUFFER) &&
                (obj.ob_type.tp_as_buffer.bf_getbuffer !is null);
        }
    }

    /** This is a C-API version of the getbuffer function call.  It checks
       to make sure object has the required function pointer and issues the
       call.  Returns -1 and raises an error on failure and returns 0 on
       success
     */
    int PyObject_GetBuffer(PyObject* obj, Py_buffer* view,
            int flags);

    /** Get the memory area pointed to by the indices for the buffer given.
       Note that view->ndim is the assumed size of indices
     */
    void* PyBuffer_GetPointer(Py_buffer* view, Py_ssize_t* indices);

    /** Return the implied itemsize of the data-format area from a
       struct-style description

       abstract.h lies; this function actually does not exist. We're lying too.
     */
    int PyBuffer_SizeFromFormat(const(char) *);

/// _
    int PyBuffer_ToContiguous(void* buf, Py_buffer* view,
            Py_ssize_t len, char fort);

    /** Copy len bytes of data from the contiguous chunk of memory
       pointed to by buf into the buffer exported by obj.  Return
       0 on success and return -1 and raise a PyBuffer_Error on
       error (i.e. the object does not have a buffer interface or
       it is not working).

       If fort is 'F' and the object is multi-dimensional,
       then the data will be copied into the array in
       Fortran-style (first dimension varies the fastest).  If
       fort is 'C', then the data will be copied into the array
       in C-style (last dimension varies the fastest).  If fort
       is 'A', then it does not matter and the copy will be made
       in whatever way is more efficient.

     */
    int PyBuffer_FromContiguous(Py_buffer* view, void* buf,
            Py_ssize_t len, char fort);



    /** Copy the data from the src buffer to the buffer of dest
     */
    int PyObject_CopyData(PyObject* dest, PyObject* src);


/// _
    int PyBuffer_IsContiguous(Py_buffer* view, char fort);


    /**  Fill the strides array with byte-strides of a contiguous
        (Fortran-style if fort is 'F' or C-style otherwise)
        array of the given shape with the given number of bytes
        per element.
     */
    void PyBuffer_FillContiguousStrides(int ndims,
            Py_ssize_t* shape,
            Py_ssize_t* strides,
            int itemsize,
            char fort);

    /** Fills in a buffer-info structure correctly for an exporter
       that can only share a contiguous chunk of memory of
       "unsigned bytes" of the given length. Returns 0 on success
       and -1 (with raising an error) on error.
     */
    int PyBuffer_FillInfo(Py_buffer* view, PyObject* o, void* buf,
            Py_ssize_t len, int readonly,
            int flags);

    /** Releases a Py_buffer obtained from getbuffer ParseTuple's s*.
     */
    void PyBuffer_Release(Py_buffer* view);

    /**
       Takes an arbitrary object and returns the result of
       calling obj.__format__(format_spec).
     */
    PyObject* PyObject_Format(PyObject* obj,
            PyObject* format_spec);

}

//-//////////////////////////////////////////////////////////////////////////
// ITERATORS
//-//////////////////////////////////////////////////////////////////////////

/// _
PyObject* PyObject_GetIter(PyObject*);

// D translation of C macro:
/// _
int PyIter_Check()(PyObject* obj) {
    version(Python_3_0_Or_Later) {
        return obj.ob_type.tp_iternext != null &&
            obj.ob_type.tp_iternext != &_PyObject_NextNotImplemented;
    }else version(Python_2_7_Or_Later) {
        return PyType_HasFeature(obj.ob_type, Py_TPFLAGS_HAVE_ITER)
            && obj.ob_type.tp_iternext != null &&
            obj.ob_type.tp_iternext != &_PyObject_NextNotImplemented;
    }else {
        return PyType_HasFeature(obj.ob_type, Py_TPFLAGS_HAVE_ITER)
            && obj.ob_type.tp_iternext != null;
    }
}

/// _
PyObject* PyIter_Next(PyObject*);

/////////////////////////////////////////////////////////////////////////////
// NUMBERS
/////////////////////////////////////////////////////////////////////////////

int PyNumber_Check(PyObject* o);

/// _
PyObject* PyNumber_Add(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_Subtract(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_Multiply(PyObject* o1, PyObject* o2);

version(Python_3_5_Or_Later) {
    /// _
    PyObject* PyNumber_MatrixMultiply(PyObject* o1, PyObject* o2);
}

version(Python_3_0_Or_Later) {
}else{
    /// Availability: 2.*
    PyObject* PyNumber_Divide(PyObject* o1, PyObject* o2);
}
/// _
PyObject* PyNumber_FloorDivide(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_TrueDivide(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_Remainder(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_Divmod(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_Power(PyObject* o1, PyObject* o2, PyObject* o3);
/// _
PyObject* PyNumber_Negative(PyObject* o);
/// _
PyObject* PyNumber_Positive(PyObject* o);
/// _
PyObject* PyNumber_Absolute(PyObject* o);
/// _
PyObject* PyNumber_Invert(PyObject* o);
/// _
PyObject* PyNumber_Lshift(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_Rshift(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_And(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_Xor(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_Or(PyObject* o1, PyObject* o2);

version(Python_2_5_Or_Later) {
/// Availability: >= 2.5
    int PyIndex_Check()(PyObject* obj) {
        version(Python_3_0_Or_Later) {
            return obj.ob_type.tp_as_number !is null &&
                obj.ob_type.tp_as_number.nb_index !is null;
        }else{
            return obj.ob_type.tp_as_number !is null &&
                PyType_HasFeature(obj.ob_type, Py_TPFLAGS_HAVE_INDEX) &&
                obj.ob_type.tp_as_number.nb_index !is null;
        }
    }
/// Availability: >= 2.5
    PyObject* PyNumber_Index(PyObject* o);
    /**
       Returns the Integral instance converted to an int. The
       instance is expected to be int or long or have an __int__
       method. Steals integral's reference. error_format will be
       used to create the TypeError if integral isn't actually an
       Integral instance. error_format should be a format string
       that can accept a char* naming integral's type.

        Availability: >= 2.5
     */
    Py_ssize_t PyNumber_AsSsize_t(PyObject* o, PyObject* exc);
}
version(Python_2_6_Or_Later) {
/// Availability: >= 2.6
    PyObject*  _PyNumber_ConvertIntegralToInt(
            PyObject* integral,
            const(char)* error_format);
}

version(Python_3_0_Or_Later) {
}else {
    /// Availability: 2.*
    PyObject* PyNumber_Int(PyObject* o);
}
/// _
PyObject* PyNumber_Long(PyObject* o);
/// _
PyObject* PyNumber_Float(PyObject* o);
/// _
PyObject* PyNumber_InPlaceAdd(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_InPlaceSubtract(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_InPlaceMultiply(PyObject* o1, PyObject* o2);

version(Python_3_5_Or_Later) {
    /// _
     PyObject* PyNumber_InPlaceMatrixMultiply(PyObject* o1, PyObject* o2);
}

version(Python_3_0_Or_Later) {
}else{
    /// Availability: 2.*
    PyObject* PyNumber_InPlaceDivide(PyObject* o1, PyObject* o2);
}
/// _
PyObject* PyNumber_InPlaceFloorDivide(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_InPlaceTrueDivide(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_InPlaceRemainder(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_InPlacePower(PyObject* o1, PyObject* o2, PyObject* o3);
/// _
PyObject* PyNumber_InPlaceLshift(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_InPlaceRshift(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_InPlaceAnd(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_InPlaceXor(PyObject* o1, PyObject* o2);
/// _
PyObject* PyNumber_InPlaceOr(PyObject* o1, PyObject* o2);

version(Python_2_6_Or_Later){
    /**
       Returns the integer n converted to a string with a base, with a base
       marker of 0b, 0o or 0x prefixed if applicable.
       If n is not an int object, it is converted with PyNumber_Index first.

Availability: >= 2.6
     */
    PyObject* PyNumber_ToBase(PyObject* n, int base);
}

//-//////////////////////////////////////////////////////////////////////////
// SEQUENCES
//-//////////////////////////////////////////////////////////////////////////

/// _
int PySequence_Check(PyObject* o);
/// _
Py_ssize_t PySequence_Size(PyObject* o);
/// _
alias PySequence_Size PySequence_Length;
/// _
PyObject* PySequence_Concat(PyObject* o1, PyObject* o2);
/// _
PyObject* PySequence_Repeat(PyObject* o, Py_ssize_t count);
/// _
PyObject* PySequence_GetItem(PyObject* o, Py_ssize_t i);
/// _
PyObject* PySequence_GetSlice(PyObject* o, Py_ssize_t i1, Py_ssize_t i2);
/// _
int PySequence_SetItem(PyObject* o, Py_ssize_t i, PyObject* v);
/// _
int PySequence_DelItem(PyObject* o, Py_ssize_t i);
/// _
int PySequence_SetSlice(PyObject* o, Py_ssize_t i1, Py_ssize_t i2, PyObject* v);
/// _
int PySequence_DelSlice(PyObject* o, Py_ssize_t i1, Py_ssize_t i2);
/// _
PyObject* PySequence_Tuple(PyObject* o);
/// _
PyObject* PySequence_List(PyObject* o);
/// _
PyObject* PySequence_Fast(PyObject* o,  const(char)* m);
// D translations of C macros:
/// _
Py_ssize_t PySequence_Fast_GET_SIZE()(PyObject* o) {
    return PyList_Check(o) ? cast(Py_ssize_t) PyList_GET_SIZE(o) :
        cast(Py_ssize_t) PyTuple_GET_SIZE(o);
}
/// _
PyObject* PySequence_Fast_GET_ITEM()(PyObject* o, Py_ssize_t i) {
    return PyList_Check(o) ? PyList_GET_ITEM(o, i) : PyTuple_GET_ITEM(o, i);
}
/// _
PyObject* PySequence_ITEM()(PyObject* o, Py_ssize_t i) {
    return o.ob_type.tp_as_sequence.sq_item(o, i);
}
/// _
PyObject** PySequence_Fast_ITEMS()(PyObject* sf) {
    return
        PyList_Check(sf) ?
        (cast(PyListObject *)sf).ob_item
        : (cast(PyTupleObject *)sf).ob_item
        ;
}
/// _
Py_ssize_t PySequence_Count(PyObject* o, PyObject* value);
/// _
enum PY_ITERSEARCH_COUNT    = 1;
/// _
enum PY_ITERSEARCH_INDEX    = 2;
/// _
enum PY_ITERSEARCH_CONTAINS = 3;
/// _
Py_ssize_t _PySequence_IterSearch(PyObject* seq, PyObject* obj, int operation);

/// _
int PySequence_In(PyObject* o, PyObject* value);
/// _
alias PySequence_In PySequence_Contains;
/// _
Py_ssize_t PySequence_Index(PyObject* o, PyObject* value);
/// _
PyObject*  PySequence_InPlaceConcat(PyObject* o1, PyObject* o2);
/// _
PyObject*  PySequence_InPlaceRepeat(PyObject* o, Py_ssize_t count);

//-//////////////////////////////////////////////////////////////////////////
// MAPPINGS
//-//////////////////////////////////////////////////////////////////////////
/// _
int PyMapping_Check(PyObject* o);
/// _
Py_ssize_t PyMapping_Length(PyObject* o);
/// _
alias PyMapping_Length PyMapping_Size;

// D translations of C macros:
/// _
int PyMapping_DelItemString()(PyObject* o, char* k) {
    return PyObject_DelItemString(o, k);
}
/// _
int PyMapping_DelItem()(PyObject* o, PyObject* k) {
    return PyObject_DelItem(o, k);
}
/// _
int PyMapping_HasKeyString(PyObject* o, char* key);
/// _
int PyMapping_HasKey(PyObject* o, PyObject* key);

version(Python_3_0_Or_Later) {
    /// _
     PyObject* PyMapping_Keys(PyObject* o);
    /// _
     PyObject* PyMapping_Values(PyObject* o);
    /// _
     PyObject* PyMapping_Items(PyObject* o);
}else {
    // D translations of C macros:
/// Availability: 2.*
    PyObject* PyMapping_Keys()(PyObject* o) {
        return PyObject_CallMethod(o, "keys", null);
    }
/// Availability: 2.*
    PyObject* PyMapping_Values()(PyObject* o) {
        return PyObject_CallMethod(o, "values", null);
    }
/// Availability: 2.*
    PyObject* PyMapping_Items()(PyObject* o) {
        return PyObject_CallMethod(o, "items", null);
    }
}
/// _
PyObject* PyMapping_GetItemString(PyObject* o, char* key);
/// _
int PyMapping_SetItemString(PyObject* o, char* key, PyObject* value);

//-//////////////////////////////////////////////////////////////////////////
// GENERIC
//-//////////////////////////////////////////////////////////////////////////
int PyObject_IsInstance(PyObject* object, PyObject* typeorclass);
/// _
int PyObject_IsSubclass(PyObject* object, PyObject* typeorclass);
version(Python_2_6_Or_Later){
/// Availability: >= 2.6
    int _PyObject_RealIsInstance(PyObject* inst, PyObject* cls);
/// Availability: >= 2.6
    int _PyObject_RealIsSubclass(PyObject* derived, PyObject* cls);
}

version(Python_3_0_Or_Later) {
    /// _
    const(char*)* _PySequence_BytesToCharpArray(PyObject* self);
    /// _
    void _Py_FreeCharPArray(const(char*)* array);
}


