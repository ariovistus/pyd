module python2.abstract_;

import util.conv;
import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/abstract.h:

// D translations of C macros:
int PyObject_DelAttrString()(PyObject* o, Char1 *a) {
    return PyObject_SetAttrString(o, a, null);
}
int PyObject_DelAttr()(PyObject* o, PyObject* a) {
    return PyObject_SetAttr(o, a, null);
}

int PyObject_Cmp(PyObject* o1, PyObject* o2, int *result);

/////////////////////////////////////////////////////////////////////////////
// CALLABLES
/////////////////////////////////////////////////////////////////////////////
int PyCallable_Check(PyObject* o);

PyObject* PyObject_Call(PyObject* callable_object, PyObject* args, PyObject* kw);
PyObject* PyObject_CallObject(PyObject* callable_object, PyObject* args);
PyObject* PyObject_CallFunction(PyObject* callable_object, char* format, ...);
PyObject* PyObject_CallMethod(PyObject* o, char* m, char* format, ...);
PyObject* PyObject_CallFunctionObjArgs(PyObject* callable, ...);
PyObject* PyObject_CallMethodObjArgs(PyObject* o,PyObject* m, ...);

/////////////////////////////////////////////////////////////////////////////
// GENERIC
/////////////////////////////////////////////////////////////////////////////
PyObject* PyObject_Type(PyObject* o);

/////////////////////////////////////////////////////////////////////////////
// CONTAINERS
/////////////////////////////////////////////////////////////////////////////

Py_ssize_t PyObject_Size(PyObject* o);
//int PyObject_Length(PyObject* o);
alias PyObject_Size PyObject_Length;
version(Python_2_6_Or_Later){
    Py_ssize_t _PyObject_LengthHint(PyObject*, Py_ssize_t);
}else version(Python_2_5_Or_Later){
    Py_ssize_t _PyObject_LengthHint(PyObject*);
}

PyObject* PyObject_GetItem(PyObject* o, PyObject* key);
int PyObject_SetItem(PyObject* o, PyObject* key, PyObject* v);
int PyObject_DelItemString(PyObject* o, char* key);
int PyObject_DelItem(PyObject* o, PyObject* key);

int PyObject_AsCharBuffer(PyObject* obj, const(char)** buffer, 
        Py_ssize_t* buffer_len);
int PyObject_CheckReadBuffer(PyObject* obj);
int PyObject_AsReadBuffer(PyObject* obj, void** buffer, Py_ssize_t* buffer_len);
int PyObject_AsWriteBuffer(PyObject* obj, void** buffer, Py_ssize_t* buffer_len);

version(Python_2_6_Or_Later){
    /* new buffer API */

    void PyObject_CheckBuffer()(PyObject* obj){
        return (obj.ob_type.tp_as_buffer !is null) &&
            PyType_HasFeature(obj.ob_type, Py_TPFLAGS_HAVE_NEWBUFFER) &&
            (obj.ob_type.tp_as_buffer.bf_getbuffer !is null);
    }

    /* Return 1 if the getbuffer function is available, otherwise
       return 0 */

    int PyObject_GetBuffer(PyObject* obj, Py_buffer* view,
            int flags);

    /* This is a C-API version of the getbuffer function call.  It checks
       to make sure object has the required function pointer and issues the
       call.  Returns -1 and raises an error on failure and returns 0 on
       success
     */


    void* PyBuffer_GetPointer(Py_buffer* view, Py_ssize_t* indices);

    /* Get the memory area pointed to by the indices for the buffer given.
       Note that view->ndim is the assumed size of indices
     */

    int PyBuffer_SizeFromFormat(const(char) *);

    /* Return the implied itemsize of the data-format area from a
       struct-style description */



    int PyBuffer_ToContiguous(void* buf, Py_buffer* view,
            Py_ssize_t len, char fort);

    int PyBuffer_FromContiguous(Py_buffer* view, void* buf,
            Py_ssize_t len, char fort);


    /* Copy len bytes of data from the contiguous chunk of memory
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

    int PyObject_CopyData(PyObject* dest, PyObject* src);

    /* Copy the data from the src buffer to the buffer of destination
     */

    int PyBuffer_IsContiguous(Py_buffer* view, char fort);


    void PyBuffer_FillContiguousStrides(int ndims,
            Py_ssize_t* shape,
            Py_ssize_t* strides,
            int itemsize,
            char fort);

    /*  Fill the strides array with byte-strides of a contiguous
        (Fortran-style if fort is 'F' or C-style otherwise)
        array of the given shape with the given number of bytes
        per element.
     */

    int PyBuffer_FillInfo(Py_buffer* view, PyObject* o, void* buf,
            Py_ssize_t len, int readonly,
            int flags);

    /* Fills in a buffer-info structure correctly for an exporter
       that can only share a contiguous chunk of memory of
       "unsigned bytes" of the given length. Returns 0 on success
       and -1 (with raising an error) on error.
     */

    void PyBuffer_Release(Py_buffer* view);

    /* Releases a Py_buffer obtained from getbuffer ParseTuple's s*.
     */

    PyObject* PyObject_Format(PyObject* obj,
            PyObject* format_spec);
    /*
       Takes an arbitrary object and returns the result of
       calling obj.__format__(format_spec).
     */

}

/////////////////////////////////////////////////////////////////////////////
// ITERATORS
/////////////////////////////////////////////////////////////////////////////
PyObject* PyObject_GetIter(PyObject*);

// D translation of C macro:
int PyIter_Check()(PyObject* obj) {
    return PyType_HasFeature(obj.ob_type, Py_TPFLAGS_HAVE_ITER)
        && obj.ob_type.tp_iternext != null;
}

PyObject* PyIter_Next(PyObject*);

/////////////////////////////////////////////////////////////////////////////
// NUMBERS
/////////////////////////////////////////////////////////////////////////////

int PyNumber_Check(PyObject* o);

PyObject* PyNumber_Add(PyObject* o1, PyObject* o2);
PyObject* PyNumber_Subtract(PyObject* o1, PyObject* o2);
PyObject* PyNumber_Multiply(PyObject* o1, PyObject* o2);
PyObject* PyNumber_Divide(PyObject* o1, PyObject* o2);
PyObject* PyNumber_FloorDivide(PyObject* o1, PyObject* o2);
PyObject* PyNumber_TrueDivide(PyObject* o1, PyObject* o2);
PyObject* PyNumber_Remainder(PyObject* o1, PyObject* o2);
PyObject* PyNumber_Divmod(PyObject* o1, PyObject* o2);
PyObject* PyNumber_Power(PyObject* o1, PyObject* o2, PyObject* o3);
PyObject* PyNumber_Negative(PyObject* o);
PyObject* PyNumber_Positive(PyObject* o);
PyObject* PyNumber_Absolute(PyObject* o);
PyObject* PyNumber_Invert(PyObject* o);
PyObject* PyNumber_Lshift(PyObject* o1, PyObject* o2);
PyObject* PyNumber_Rshift(PyObject* o1, PyObject* o2);
PyObject* PyNumber_And(PyObject* o1, PyObject* o2);
PyObject* PyNumber_Xor(PyObject* o1, PyObject* o2);
PyObject* PyNumber_Or(PyObject* o1, PyObject* o2);

version(Python_2_5_Or_Later){
    int PyIndex_Check()(PyObject* obj) {
        return obj.ob_type.tp_as_number !is null &&
            PyType_HasFeature(obj.ob_type, Py_TPFLAGS_HAVE_INDEX) &&
            obj.ob_type.tp_as_number.nb_index !is null;
    }
    PyObject* PyNumber_Index(PyObject* o);
    Py_ssize_t PyNumber_AsSsize_t(PyObject* o, PyObject* exc);
}
version(Python_2_6_Or_Later){
    /*
       Returns the Integral instance converted to an int. The
       instance is expected to be int or long or have an __int__
       method. Steals integral's reference. error_format will be
       used to create the TypeError if integral isn't actually an
       Integral instance. error_format should be a format string
       that can accept a char* naming integral's type.
     */

    PyObject*  _PyNumber_ConvertIntegralToInt(
            PyObject* integral,
            const(char)* error_format);
}

PyObject* PyNumber_Int(PyObject* o);
PyObject* PyNumber_Long(PyObject* o);
PyObject* PyNumber_Float(PyObject* o);

PyObject* PyNumber_InPlaceAdd(PyObject* o1, PyObject* o2);
PyObject* PyNumber_InPlaceSubtract(PyObject* o1, PyObject* o2);
PyObject* PyNumber_InPlaceMultiply(PyObject* o1, PyObject* o2);
PyObject* PyNumber_InPlaceDivide(PyObject* o1, PyObject* o2);
PyObject* PyNumber_InPlaceFloorDivide(PyObject* o1, PyObject* o2);
PyObject* PyNumber_InPlaceTrueDivide(PyObject* o1, PyObject* o2);
PyObject* PyNumber_InPlaceRemainder(PyObject* o1, PyObject* o2);
PyObject* PyNumber_InPlacePower(PyObject* o1, PyObject* o2, PyObject* o3);
PyObject* PyNumber_InPlaceLshift(PyObject* o1, PyObject* o2);
PyObject* PyNumber_InPlaceRshift(PyObject* o1, PyObject* o2);
PyObject* PyNumber_InPlaceAnd(PyObject* o1, PyObject* o2);
PyObject* PyNumber_InPlaceXor(PyObject* o1, PyObject* o2);
PyObject* PyNumber_InPlaceOr(PyObject* o1, PyObject* o2);

version(Python_2_6_Or_Later){
    PyObject* PyNumber_ToBase(PyObject* n, int base);

    /*
       Returns the integer n converted to a string with a base, with a base
       marker of 0b, 0o or 0x prefixed if applicable.
       If n is not an int object, it is converted with PyNumber_Index first.
     */
}

/////////////////////////////////////////////////////////////////////////////
// SEQUENCES
/////////////////////////////////////////////////////////////////////////////

int PySequence_Check(PyObject* o);
Py_ssize_t PySequence_Size(PyObject* o);
alias PySequence_Size PySequence_Length;

PyObject* PySequence_Concat(PyObject* o1, PyObject* o2);
PyObject* PySequence_Repeat(PyObject* o, Py_ssize_t count);
PyObject* PySequence_GetItem(PyObject* o, Py_ssize_t i);
PyObject* PySequence_GetSlice(PyObject* o, Py_ssize_t i1, Py_ssize_t i2);

int PySequence_SetItem(PyObject* o, Py_ssize_t i, PyObject* v);
int PySequence_DelItem(PyObject* o, Py_ssize_t i);
int PySequence_SetSlice(PyObject* o, Py_ssize_t i1, Py_ssize_t i2, PyObject* v);
int PySequence_DelSlice(PyObject* o, Py_ssize_t i1, Py_ssize_t i2);

PyObject* PySequence_Tuple(PyObject* o);
PyObject* PySequence_List(PyObject* o);

PyObject* PySequence_Fast(PyObject* o,  const(char)* m);
// D translations of C macros:
Py_ssize_t PySequence_Fast_GET_SIZE()(PyObject* o) {
    return PyList_Check(o) ? cast(Py_ssize_t) PyList_GET_SIZE(o) :
        cast(Py_ssize_t) PyTuple_GET_SIZE(o);
}
PyObject* PySequence_Fast_GET_ITEM()(PyObject* o, Py_ssize_t i) {
    return PyList_Check(o) ? PyList_GET_ITEM(o, i) : PyTuple_GET_ITEM(o, i);
}
PyObject* PySequence_ITEM()(PyObject* o, Py_ssize_t i) {
    return o.ob_type.tp_as_sequence.sq_item(o, i);
}
PyObject** PySequence_Fast_ITEMS()(PyObject* sf) {
    return
        PyList_Check(sf) ?
        (cast(PyListObject *)sf).ob_item
        : (cast(PyTupleObject *)sf).ob_item
        ;
}

Py_ssize_t PySequence_Count(PyObject* o, PyObject* value);
int PySequence_Contains(PyObject* seq, PyObject* ob);

int PY_ITERSEARCH_COUNT    = 1;
int PY_ITERSEARCH_INDEX    = 2;
int PY_ITERSEARCH_CONTAINS = 3;

Py_ssize_t _PySequence_IterSearch(PyObject* seq, PyObject* obj, int operation);
//int PySequence_In(PyObject* o, PyObject* value);
alias PySequence_Contains PySequence_In;
Py_ssize_t PySequence_Index(PyObject* o, PyObject* value);

PyObject*  PySequence_InPlaceConcat(PyObject* o1, PyObject* o2);
PyObject*  PySequence_InPlaceRepeat(PyObject* o, Py_ssize_t count);

/////////////////////////////////////////////////////////////////////////////
// MAPPINGS
/////////////////////////////////////////////////////////////////////////////
int PyMapping_Check(PyObject* o);
Py_ssize_t PyMapping_Size(PyObject* o);
//int PyMapping_Length(PyObject* o);
alias PyMapping_Size PyMapping_Length;

// D translations of C macros:
int PyMapping_DelItemString()(PyObject* o, char* k) {
    return PyObject_DelItemString(o, k);
}
int PyMapping_DelItem()(PyObject* o, PyObject* k) {
    return PyObject_DelItem(o, k);
}

int PyMapping_HasKeyString(PyObject* o, char* key);
int PyMapping_HasKey(PyObject* o, PyObject* key);

// D translations of C macros:
PyObject* PyMapping_Keys()(PyObject* o) {
    return PyObject_CallMethod(o, zc("keys"), null);
}
PyObject* PyMapping_Values()(PyObject* o) {
    return PyObject_CallMethod(o, zc("values"), null);
}
PyObject* PyMapping_Items()(PyObject* o) {
    return PyObject_CallMethod(o, zc("items"), null);
}

PyObject* PyMapping_GetItemString(PyObject* o, char* key);
int PyMapping_SetItemString(PyObject* o, char* key, PyObject* value);

/////////////////////////////////////////////////////////////////////////////
// GENERIC
/////////////////////////////////////////////////////////////////////////////
int PyObject_IsInstance(PyObject* object, PyObject* typeorclass);
int PyObject_IsSubclass(PyObject* object, PyObject* typeorclass);

version(Python_2_6_Or_Later){
    int _PyObject_RealIsInstance(PyObject* inst, PyObject* cls);

    int _PyObject_RealIsSubclass(PyObject* derived, PyObject* cls);
}


