/**
  Mirror _object.h

Object and type object interface

Objects are structures allocated on the heap.  Special rules apply to
the use of objects to ensure they are properly garbage-collected.
Objects are never allocated statically or on the stack; they must be
accessed through special macros and functions only.  (Type objects are
exceptions to the first rule; the standard types are represented by
statically initialized type objects, although work on type/class unification
for Python 2.2 made it possible to have heap-allocated type objects too).

An object has a 'reference count' that is increased or decreased when a
pointer to the object is copied or deleted; when the reference count
reaches zero there are no references to the object left and it can be
removed from the heap.

An object has a 'type' that determines what it represents and what kind
of data it contains.  An object's type is fixed when it is created.
Types themselves are represented as objects; an object contains a
pointer to the corresponding type object.  The type itself has a type
pointer pointing to the object representing the type 'type', which
contains a pointer to itself!).

Objects do not float around in memory; once allocated an object keeps
the same size and address.  Objects that must hold variable-size data
can contain pointers to variable-size parts of the object.  Not all
objects of the same type have the same size; but the size cannot change
after allocation.  (These restrictions are made so a reference to an
object can be simply a pointer -- moving an object would require
updating all the pointers, and changing an object's size would require
moving it if there was another object right next to it.)

Objects are always accessed through pointers of the type 'PyObject *'.
The type 'PyObject' is a structure that only contains the reference count
and the type pointer.  The actual memory allocated for an object
contains other data that can only be accessed after casting the pointer
to a pointer to a longer structure type.  This longer type must start
with the reference count and type fields; the macro PyObject_HEAD should be
used for this (to accommodate for future changes).  The implementation
of a particular object type can cast the object pointer to the proper
type and back.

A standard interface exists for objects that contain an array of items
whose size is determined when the object is allocated.
  */
module deimos.python.object;

import core.stdc.stdio;
import deimos.python.pyport;
import deimos.python.methodobject;
import deimos.python.structmember;
import deimos.python.descrobject;

extern(C):
// Python-header-file: Include/object.h:

// XXX:Conditionalize in if running debug build of Python interpreter:
/*
   version (Python_Debug_Build) {
   template _PyObject_HEAD_EXTRA() {
   PyObject *_ob_next;
   PyObject *_ob_prev;
   }
   } else {
 */
/// _
template _PyObject_HEAD_EXTRA() {}
/*}*/

version(Python_3_0_Or_Later) {
    /// _
    mixin template PyObject_HEAD() {
        /// _
        PyObject ob_base;
    }
}else{
    /// _
    mixin template PyObject_HEAD() {
        mixin _PyObject_HEAD_EXTRA;
        /// _
        Py_ssize_t ob_refcnt;
        /// _
        PyTypeObject* ob_type;
    }
}

/** Nothing is actually declared to be a PyObject, but every pointer to
 * a Python object can be cast to a PyObject*.  This is inheritance built
 * by hand.  Similarly every pointer to a variable-size Python object can,
 * in addition, be cast to PyVarObject*.
 */
struct PyObject {
    version(Python_3_0_Or_Later) {
        version(Issue7758Fixed) {
            mixin _PyObject_HEAD_EXTRA;
        }
        Py_ssize_t ob_refcnt;
        PyTypeObject* ob_type;
    }else {
        mixin PyObject_HEAD;
    }
}

/**
Denotes a borrowed reference.
(Not part of Python api)

Intended use: An api function Foo returning a borrowed reference will
have return type Borrowed!PyObject* instead of PyObject*. Py_INCREF can
be used to get the original type back.

Params:
T = Python object type (PyObject, PyTypeObject, etc)

Example:
---
Borrowed!PyObject* borrowed = PyTuple_GetItem(tuple, 0);
PyObject* item = Py_XINCREF(borrowed);
---
*/
struct Borrowed(T) { }
alias Borrowed!PyObject PyObject_BorrowedRef;
/**
Convert a python reference to borrowed reference.
(Not part of Python api)
*/
Borrowed!T* borrowed(T)(T* obj) {
    return cast(Borrowed!T*) obj;
}

version(Python_3_0_Or_Later) {
    /// _
    mixin template PyObject_VAR_HEAD() {
        /// _
        PyVarObject ob_base;
    }
}else {
    /** PyObject_VAR_HEAD defines the initial segment of all variable-size
     * container objects.  These end with a declaration of an array with 1
     * element, but enough space is malloc'ed so that the array actually
     * has room for ob_size elements.  Note that ob_size is an element count,
     * not necessarily a byte count.
     */
    mixin template PyObject_VAR_HEAD() {
        mixin PyObject_HEAD;
        /// _
        Py_ssize_t ob_size; /* Number of items in variable part */
    }
}

/// _
struct PyVarObject {
    version(Python_3_0_Or_Later) {
        version(Issue7758Fixed) {
            mixin PyObject_HEAD;
        }else{
            PyObject ob_base;
        }
        Py_ssize_t ob_size; /* Number of items in variable part */
    }else{
        mixin PyObject_VAR_HEAD;
    }
}

/// _
auto Py_REFCNT(T)(T* ob) {
    return (cast(PyObject*)ob).ob_refcnt;
}
/// _
auto Py_TYPE(T)(T* ob) {
    return (cast(PyObject*)ob).ob_type;
}
/// _
auto Py_SIZE(T)(T* ob) {
    return (cast(PyVarObject*)ob).ob_size;
}

/// Not part of the python api, but annoying to do without.
void Py_SET_REFCNT(T)(T* ob, int refcnt) {
    (cast(PyObject*) ob).ob_refcnt = refcnt;
}
/// ditto
void Py_SET_TYPE(T)(T* ob, PyTypeObject* tipo) {
    (cast(PyObject*)ob).ob_type = tipo;
}
/// ditto
void Py_SET_SIZE(T)(T* ob, Py_ssize_t size) {
    (cast(PyVarObject*)ob).ob_size = size;
}

/// _
alias PyObject* function(PyObject*) unaryfunc;
/// _
alias PyObject* function(PyObject*, PyObject*) binaryfunc;
/// _
alias PyObject* function(PyObject*, PyObject*, PyObject*) ternaryfunc;
/// _
alias Py_ssize_t function(PyObject*) lenfunc;
/// _
alias lenfunc inquiry;
version(Python_3_0_Or_Later) {
}else{
    /// Availability: 2.*
    alias int function(PyObject**, PyObject**) coercion;
}
/// _
alias PyObject* function(PyObject*, Py_ssize_t) ssizeargfunc;
/// _
alias PyObject* function(PyObject*, Py_ssize_t, Py_ssize_t) ssizessizeargfunc;
version(Python_2_5_Or_Later){
}else{
    /// Availability: 2.4
    alias ssizeargfunc intargfunc;
    /// Availability: 2.4
    alias ssizessizeargfunc intintargfunc;
}
/// _
alias int function(PyObject*, Py_ssize_t, PyObject*) ssizeobjargproc;
/// _
alias int function(PyObject*, Py_ssize_t, Py_ssize_t, PyObject*) ssizessizeobjargproc;
version(Python_2_5_Or_Later){
}else{
    /// Availability: 2.4
    alias ssizeobjargproc intobjargproc;
    /// Availability: 2.4
    alias ssizessizeobjargproc intintobjargproc;
}
/// _
alias int function(PyObject*, PyObject*, PyObject*) objobjargproc;

version(Python_3_0_Or_Later) {
}else{
    /// ssize_t-based buffer interface
    /// Availability: 2.*
    alias Py_ssize_t function(PyObject*, Py_ssize_t, void**) readbufferproc;
    /// ditto
    alias Py_ssize_t function(PyObject*, Py_ssize_t, void**) writebufferproc;
    /// ditto
    alias Py_ssize_t function(PyObject*, Py_ssize_t*) segcountproc;
    /// ditto
    alias Py_ssize_t function(PyObject*, Py_ssize_t, char**) charbufferproc;
}
version(Python_2_5_Or_Later){
}else{
    /// int-based buffer interface
    /// Availability: 2.4
    alias readbufferproc getreadbufferproc;
    /// ditto
    alias writebufferproc getwritebufferproc;
    /// ditto
    alias segcountproc getsegcountproc;
    /// ditto
    alias charbufferproc getcharbufferproc;
}

version(Python_2_6_Or_Later){
    /** Py3k buffer interface */
    /// Availability: >= 2.6
    struct Py_buffer{
        void* buf;
        /** borrowed reference */
        Borrowed!PyObject* obj;
        /// _
        Py_ssize_t len;
        /** This is Py_ssize_t so it can be
          pointed to by strides in simple case.*/
        Py_ssize_t itemsize;
        /// _
        int readonly;
        /// _
        int ndim;
        /// _
        char* format;
        /// _
        Py_ssize_t* shape;
        /// _
        Py_ssize_t* strides;
        /// _
        Py_ssize_t* suboffsets;
        version(Python_3_4_Or_Later) {
        }else version(Python_2_7_Or_Later) {
            /** static store for shape and strides of
              mono-dimensional buffers. */
            /// Availability: >= 2.7 < 3.4
            Py_ssize_t[2] smalltable;
        }
        /// _
        void* internal;
    };

    /// Availability: >= 2.6
    alias int function(PyObject*, Py_buffer*, int) getbufferproc;
    /// Availability: >= 2.6
    alias void function(PyObject*, Py_buffer*) releasebufferproc;

    /** Flags for getting buffers */
    /// Availability: >= 2.6
    enum PyBUF_SIMPLE = 0;
    /// ditto
    enum PyBUF_WRITABLE = 0x0001;
    /*  we used to include an E, backwards compatible alias  */
    /// ditto
    enum PyBUF_WRITEABLE = PyBUF_WRITABLE;
    /// ditto
    enum PyBUF_FORMAT = 0x0004;
    /// ditto
    enum PyBUF_ND = 0x0008;
    /// ditto
    enum PyBUF_STRIDES = (0x0010 | PyBUF_ND);
    /// ditto
    enum PyBUF_C_CONTIGUOUS = (0x0020 | PyBUF_STRIDES);
    /// ditto
    enum PyBUF_F_CONTIGUOUS = (0x0040 | PyBUF_STRIDES);
    /// ditto
    enum PyBUF_ANY_CONTIGUOUS = (0x0080 | PyBUF_STRIDES);
    /// ditto
    enum PyBUF_INDIRECT = (0x0100 | PyBUF_STRIDES);

    /// ditto
    enum PyBUF_CONTIG = (PyBUF_ND | PyBUF_WRITABLE);
    /// ditto
    enum PyBUF_CONTIG_RO = (PyBUF_ND);

    /// ditto
    enum PyBUF_STRIDED = (PyBUF_STRIDES | PyBUF_WRITABLE);
    /// ditto
    enum PyBUF_STRIDED_RO = (PyBUF_STRIDES);

    /// ditto
    enum PyBUF_RECORDS = (PyBUF_STRIDES | PyBUF_WRITABLE | PyBUF_FORMAT);
    /// ditto
    enum PyBUF_RECORDS_RO = (PyBUF_STRIDES | PyBUF_FORMAT);

    /// ditto
    enum PyBUF_FULL = (PyBUF_INDIRECT | PyBUF_WRITABLE | PyBUF_FORMAT);
    /// ditto
    enum PyBUF_FULL_RO = (PyBUF_INDIRECT | PyBUF_FORMAT);


    /// ditto
    enum PyBUF_READ  = 0x100;
    /// ditto
    enum PyBUF_WRITE = 0x200;
    /// ditto
    enum PyBUF_SHADOW = 0x400;
    /* end Py3k buffer interface */
}

/// _
alias int function(PyObject*, PyObject*) objobjproc;
/// _
alias int function(PyObject*, void*) visitproc;
/// _
alias int function(PyObject*, visitproc, void*) traverseproc;

/** For numbers without flag bit Py_TPFLAGS_CHECKTYPES set, all
   arguments are guaranteed to be of the object's type (modulo
   coercion hacks -- i.e. if the type's coercion function
   returns other types, then these are allowed as well).  Numbers that
   have the Py_TPFLAGS_CHECKTYPES flag bit set should check *both*
   arguments for proper type and implement the necessary conversions
   in the slot functions themselves. */
struct PyNumberMethods {
    binaryfunc nb_add;
    binaryfunc nb_subtract;
    binaryfunc nb_multiply;
    version(Python_3_0_Or_Later) {
    }else {
        binaryfunc nb_divide;
    }
    binaryfunc nb_remainder;
    binaryfunc nb_divmod;
    ternaryfunc nb_power;
    unaryfunc nb_negative;
    unaryfunc nb_positive;
    unaryfunc nb_absolute;
    version(Python_3_0_Or_Later) {
        inquiry nb_bool;
    }else {
        inquiry nb_nonzero;
    }
    unaryfunc nb_invert;
    binaryfunc nb_lshift;
    binaryfunc nb_rshift;
    binaryfunc nb_and;
    binaryfunc nb_xor;
    binaryfunc nb_or;
    version(Python_3_0_Or_Later) {
    }else{
        coercion nb_coerce;
    }
    unaryfunc nb_int;
    version(Python_3_0_Or_Later) {
        void* nb_reserved;  /* the slot formerly known as nb_long */
    }else{
        unaryfunc nb_long;
    }
    unaryfunc nb_float;
    version(Python_3_0_Or_Later) {
    }else{
        unaryfunc nb_oct;
        unaryfunc nb_hex;
    }

    binaryfunc nb_inplace_add;
    binaryfunc nb_inplace_subtract;
    binaryfunc nb_inplace_multiply;
    version(Python_3_0_Or_Later) {
    }else{
        binaryfunc nb_inplace_divide;
    }
    binaryfunc nb_inplace_remainder;
    ternaryfunc nb_inplace_power;
    binaryfunc nb_inplace_lshift;
    binaryfunc nb_inplace_rshift;
    binaryfunc nb_inplace_and;
    binaryfunc nb_inplace_xor;
    binaryfunc nb_inplace_or;

    /** These require the Py_TPFLAGS_HAVE_CLASS flag */
    binaryfunc nb_floor_divide;
    ///ditto
    binaryfunc nb_true_divide;
    ///ditto
    binaryfunc nb_inplace_floor_divide;
    ///ditto
    binaryfunc nb_inplace_true_divide;

    version(Python_2_5_Or_Later){
        /// Availability: >= 2.5
        unaryfunc nb_index;
    }

    version(Python_3_5_Or_Later) {
        binaryfunc nb_matrix_multiply;
        binaryfunc nb_inplace_matrix_multiply;
    }
}

/// _
struct PySequenceMethods {
    /// _
    lenfunc sq_length;
    /// _
    binaryfunc sq_concat;
    /// _
    ssizeargfunc sq_repeat;
    /// _
    ssizeargfunc sq_item;
    version(Python_3_0_Or_Later) {
        /// _
        void* was_sq_slice;
    }else{
        /// Availability: 2.*
        ssizessizeargfunc sq_slice;
    }
    /// _
    ssizeobjargproc sq_ass_item;
    version(Python_3_0_Or_Later) {
        /// _
        void* was_sq_ass_slice;
    }else{
        /// Availability: 2.*
        ssizessizeobjargproc sq_ass_slice;
    }
    /// _
    objobjproc sq_contains;
    /// _
    binaryfunc sq_inplace_concat;
    /// _
    ssizeargfunc sq_inplace_repeat;
}

/// _
struct PyMappingMethods {
    /// _
    lenfunc mp_length;
    /// _
    binaryfunc mp_subscript;
    /// _
    objobjargproc mp_ass_subscript;
}

version(Python_3_5_Or_Later) {
    /// _
    struct PyAsyncMethods {
        unaryfunc am_await;
        unaryfunc am_aiter;
        unaryfunc am_anext;
    }
}

/// _
struct PyBufferProcs {
    version(Python_3_0_Or_Later) {
    }else{
        /// Availability: 3.*
        readbufferproc bf_getreadbuffer;
        /// Availability: 3.*
        writebufferproc bf_getwritebuffer;
        /// Availability: 3.*
        segcountproc bf_getsegcount;
        /// Availability: 3.*
        charbufferproc bf_getcharbuffer;
    }
    version(Python_2_6_Or_Later){
        /// Availability: 2.6, 2.7
        getbufferproc bf_getbuffer;
        /// Availability: 2.6, 2.7
        releasebufferproc bf_releasebuffer;
    }
}


/// _
alias void function(void*) freefunc;
/// _
alias void function(PyObject*) destructor;
/// _
alias int function(PyObject*, FILE*, int) printfunc;
/// _
alias PyObject* function(PyObject*, char*) getattrfunc;
/// _
alias PyObject* function(PyObject*, PyObject*) getattrofunc;
/// _
alias int function(PyObject*, char*, PyObject*) setattrfunc;
/// _
alias int function(PyObject*, PyObject*, PyObject*) setattrofunc;
version(Python_3_0_Or_Later) {
}else{
    /// Availability: 2.*
    alias int function(PyObject*, PyObject*) cmpfunc;
}
/// _
alias PyObject* function(PyObject*) reprfunc;
/// _
alias Py_hash_t function(PyObject*) hashfunc;
/// _
alias PyObject* function(PyObject*, PyObject*, int) richcmpfunc;
/// _
alias PyObject* function(PyObject*) getiterfunc;
/// _
alias PyObject* function(PyObject*) iternextfunc;
/// _
alias PyObject* function(PyObject*, PyObject*, PyObject*) descrgetfunc;
/// _
alias int function(PyObject*, PyObject*, PyObject*) descrsetfunc;
/// _
alias int function(PyObject*, PyObject*, PyObject*) initproc;
/// _
alias PyObject* function(PyTypeObject*, PyObject*, PyObject*) newfunc;
/// _
alias PyObject* function(PyTypeObject*, Py_ssize_t) allocfunc;

/**
Type objects contain a string containing the type name (to help somewhat
in debugging), the allocation parameters (see PyObject_New() and
PyObject_NewVar()),
and methods for accessing objects of the type.  Methods are optional, a
nil pointer meaning that particular kind of access is not available for
this type.  The Py_DECREF() macro uses the tp_dealloc method without
checking for a nil pointer; it should always be implemented except if
the implementation can guarantee that the reference count will never
reach zero (e.g., for statically allocated type objects).

NB: the methods for certain type groups are now contained in separate
method blocks.
*/
struct PyTypeObject {
    version(Issue7758Fixed) {
        mixin PyObject_VAR_HEAD;
    }else{
        version(Python_3_0_Or_Later) {
            PyVarObject ob_base;
        }else {
            Py_ssize_t ob_refcnt;
            PyTypeObject* ob_type;
            Py_ssize_t ob_size; /* Number of items in variable part */
        }
    }
    /** For printing, in format "<module>.<name>" */
    const(char)* tp_name;
    /** For allocation */
    Py_ssize_t tp_basicsize, tp_itemsize;

    /** Methods to implement standard operations */
    destructor tp_dealloc;
    /// ditto
    printfunc tp_print;
    /// ditto
    getattrfunc tp_getattr;
    /// ditto
    setattrfunc tp_setattr;
    /// ditto
    version(Python_3_5_Or_Later) {
        PyAsyncMethods* tp_as_async;
    }else version(Python_3_0_Or_Later) {
        void* tp_reserved; 
    }else{
        cmpfunc tp_compare;
    }
    /// ditto
    reprfunc tp_repr;

    /** Method suites for standard classes */
    PyNumberMethods* tp_as_number;
    /// ditto
    PySequenceMethods* tp_as_sequence;
    /// ditto
    PyMappingMethods* tp_as_mapping;

    /** More standard operations (here for binary compatibility) */
    hashfunc tp_hash;
    /// ditto
    ternaryfunc tp_call;
    /// ditto
    reprfunc tp_str;
    /// ditto
    getattrofunc tp_getattro;
    /// ditto
    setattrofunc tp_setattro;

    /** Functions to access object as input/output buffer */
    PyBufferProcs* tp_as_buffer;

    /** Flags to define presence of optional/expanded features */
    C_ulong tp_flags;

    /** Documentation string */
    const(char)* tp_doc;

    /** call function for all accessible objects */
    traverseproc tp_traverse;

    /** delete references to contained objects */
    inquiry tp_clear;

    /** rich comparisons */
    richcmpfunc tp_richcompare;

    /** weak reference enabler */
    version(Python_2_5_Or_Later){
        Py_ssize_t tp_weaklistoffset;
    }else{
        C_long tp_weaklistoffset;
    }

    /** Iterators */
    getiterfunc tp_iter;
    /// ditto
    iternextfunc tp_iternext;

    /** Attribute descriptor and subclassing stuff */
    PyMethodDef* tp_methods;
    /// ditto
    PyMemberDef* tp_members;
    /// ditto
    PyGetSetDef* tp_getset;
    /// ditto
    PyTypeObject* tp_base;
    /// ditto
    PyObject* tp_dict;
    /// ditto
    descrgetfunc tp_descr_get;
    /// ditto
    descrsetfunc tp_descr_set;
    /// ditto
    version(Python_2_5_Or_Later){
        Py_ssize_t tp_dictoffset;
    }else{
        C_long tp_dictoffset;
    }
    /// ditto
    initproc tp_init;
    /// ditto
    allocfunc tp_alloc;
    /// ditto
    newfunc tp_new;
    /** Low-level free-memory routine */
    freefunc tp_free;
    /** For PyObject_IS_GC */
    inquiry tp_is_gc;
    /// _
    PyObject* tp_bases;
    /** method resolution order */
    PyObject* tp_mro;
    /// _
    PyObject* tp_cache;
    /// _
    PyObject* tp_subclasses;
    /// _
    PyObject* tp_weaklist;
    /// _
    destructor tp_del;
    version(Python_2_6_Or_Later){
        /** Type attribute cache version tag. Added in version 2.6 */
        uint tp_version_tag;
    }

    version(Python_3_0_Or_Later) {
        /// Availability: 3.??
        destructor tp_finalize;
    }
}

version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    struct PyType_Slot{
        /** slot id, see below */
        int slot;
        /** function pointer */
        void* pfunc;
    }

    /// Availability: 3.*
    struct PyType_Spec{
        /// _
        const(char)* name;
        /// _
        int basicsize;
        /// _
        int itemsize;
        /// _
        int flags;
        /** terminated by slot==0. */
        PyType_Slot* slots;
    }

    /// Availability: 3.*
    PyObject* PyType_FromSpec(PyType_Spec*);
}

/** The *real* layout of a type object when allocated on the heap */
struct PyHeapTypeObject {
    version(Python_2_5_Or_Later){
        /// Availability: >= 2.5
        PyTypeObject ht_type;
    }else{
        /// Availability: 2.4
        PyTypeObject type;
    }
    version(Python_3_5_Or_Later) {
        /// Availability: >= 3.5
        PyAsyncMethods as_async;
    }
    /// _
    PyNumberMethods as_number;
    /// _
    PyMappingMethods as_mapping;
    /** as_sequence comes after as_mapping,
       so that the mapping wins when both
       the mapping and the sequence define
       a given operator (e.g. __getitem__).
       see add_operators() in typeobject.c . */
    PySequenceMethods as_sequence;
    /// _
    PyBufferProcs as_buffer;
    version(Python_2_5_Or_Later){
        /// Availability: >= 2.5
        PyObject* ht_name;
        /// Availability: >= 2.5
        PyObject* ht_slots;
    }else{
        /// Availability: 2.4
        PyObject* name;
        /// Availability: 2.4
        PyObject* slots;
    }
}

/** Generic type check */
int PyType_IsSubtype(PyTypeObject*, PyTypeObject*);

// D translation of C macro:
/// _
int PyObject_TypeCheck()(PyObject* ob, PyTypeObject* tp) {
    return (ob.ob_type == tp || PyType_IsSubtype(ob.ob_type, tp));
}

/** built-in 'type' */
mixin(PyAPI_DATA!"PyTypeObject PyType_Type");
/** built-in 'object' */
mixin(PyAPI_DATA!"PyTypeObject PyBaseObject_Type");
/** built-in 'super' */
mixin(PyAPI_DATA!"PyTypeObject PySuper_Type");

version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    C_long PyType_GetFlags(PyTypeObject*);
}

// D translation of C macro:
/// _
int PyType_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, &PyType_Type);
}
// D translation of C macro:
/// _
int PyType_CheckExact()(PyObject* op) {
    return op.ob_type == &PyType_Type;
}

/// _
int PyType_Ready(PyTypeObject*);
/// _
PyObject* PyType_GenericAlloc(PyTypeObject*, Py_ssize_t);
/// _
PyObject* PyType_GenericNew(PyTypeObject*, PyObject*, PyObject*);
/// _
PyObject* _PyType_Lookup(PyTypeObject*, PyObject*);
/// _
version(Python_2_7_Or_Later) {
    /// Availability: >= 2.7
    PyObject* _PyObject_LookupSpecial(PyObject*, char*, PyObject**);
}
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    PyTypeObject* _PyType_CalculateMetaclass(PyTypeObject*, PyObject*);
}
version(Python_2_6_Or_Later){
    /// Availability: >= 2.6
    uint PyType_ClearCache();
    /// Availability: >= 2.6
    void PyType_Modified(PyTypeObject *);
}

/// _
int PyObject_Print(PyObject*, FILE*, int);
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    void _Py_BreakPoint();
}
/// _
PyObject* PyObject_Repr(PyObject*);
version(Python_3_0_Or_Later) {
}else version(Python_2_5_Or_Later) {
    /// Availability: 2.5, 2.6, 2.7
    PyObject* _PyObject_Str(PyObject*);
}
/// _
PyObject* PyObject_Str(PyObject*);

version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    PyObject* PyObject_ASCII(PyObject*);
    /// Availability: 3.*
    PyObject* PyObject_Bytes(PyObject*);
}else{
    /// Availability: 2.*
    alias PyObject_Str PyObject_Bytes;
    /// Availability: 2.*
    PyObject * PyObject_Unicode(PyObject*);
    /// Availability: 2.*
    int PyObject_Compare(PyObject*, PyObject*);
}
/// _
PyObject* PyObject_RichCompare(PyObject*, PyObject*, int);
/// _
int PyObject_RichCompareBool(PyObject*, PyObject*, int);
/// _
PyObject* PyObject_GetAttrString(PyObject*, const(char)*);
/// _
int PyObject_SetAttrString(PyObject*, const(char)*, PyObject*);
/// _
int PyObject_HasAttrString(PyObject*, const(char)*);
/// _
PyObject* PyObject_GetAttr(PyObject*, PyObject*);
/// _
int PyObject_SetAttr(PyObject*, PyObject*, PyObject*);
/// _
int PyObject_HasAttr(PyObject*, PyObject*);
/// _
PyObject* PyObject_SelfIter(PyObject*);
/// _
PyObject* PyObject_GenericGetAttr(PyObject*, PyObject*);
/// _
int PyObject_GenericSetAttr(PyObject*,
        PyObject*, PyObject*);
/// _
Py_hash_t PyObject_Hash(PyObject*);
version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    Py_hash_t PyObject_HashNotImplemented(PyObject*);
}
/// _
int PyObject_IsTrue(PyObject*);
/// _
int PyObject_Not(PyObject*);
/// _
int PyCallable_Check(PyObject*);
version(Python_3_0_Or_Later) {
}else{
    /// Availability: 2.*
    int PyNumber_Coerce(PyObject**, PyObject**);
    /// Availability: 2.*
    int PyNumber_CoerceEx(PyObject**, PyObject**);
}

/// _
void PyObject_ClearWeakRefs(PyObject*);

/** PyObject_Dir(obj) acts like Python __builtin__.dir(obj), returning a
   list of strings.  PyObject_Dir(NULL) is like __builtin__.dir(),
   returning the names of the current locals.  In this case, if there are
   no current locals, NULL is returned, and PyErr_Occurred() is false.
*/
PyObject * PyObject_Dir(PyObject *);

/** Helpers for printing recursive container types */
int Py_ReprEnter(PyObject *);
/// ditto
void Py_ReprLeave(PyObject *);

/// _
Py_hash_t _Py_HashDouble(double);
/// _
Py_hash_t _Py_HashPointer(void*);

version(Python_3_1_Or_Later) {
    version = Py_HashSecret;
}else version(Python_3_0_Or_Later) {
}else version(Python_2_7_Or_Later) {
    version = Py_HashSecret;
}
version(Py_HashSecret) {
    /// Availability: 2.7, >= 3.1
    struct _Py_HashSecret_t{
        /// _
        Py_hash_t prefix;
        /// _
        Py_hash_t suffix;
    }
    /// Availability: 2.7, >= 3.1
    mixin(PyAPI_DATA!"_Py_HashSecret_t _Py_HashSecret");
}

/// _
auto PyObject_REPR()(PyObject* obj) {
    version(Python_3_0_Or_Later) {
        import deimos.python.unicodeobject;
        return _PyUnicode_AsString(PyObject_Repr(obj));
    }else{
        import deimos.python.stringobject;
        return PyString_AS_STRING(PyObject_Repr(obj));
    }
}
/// _
enum int Py_PRINT_RAW = 1;


version(Python_3_0_Or_Later) {
}else{
    /** PyBufferProcs contains bf_getcharbuffer */
    /// Availability: 2.*
    enum int Py_TPFLAGS_HAVE_GETCHARBUFFER       = 1L<<0;
    /** PySequenceMethods contains sq_contains */
    /// Availability: 2.*
    enum int Py_TPFLAGS_HAVE_SEQUENCE_IN         = 1L<<1;
    /** This is here for backwards compatibility.
      Extensions that use the old GC
      API will still compile but the objects will not be tracked by the GC. */
    /// Availability: 2.*
    enum int Py_TPFLAGS_GC                       = 0;
    /** PySequenceMethods and PyNumberMethods contain in-place operators */
    /// Availability: 2.*
    enum int Py_TPFLAGS_HAVE_INPLACEOPS          = 1L<<3;
    /** PyNumberMethods do their own coercion */
    /// Availability: 2.*
    enum int Py_TPFLAGS_CHECKTYPES               = 1L<<4;
    /** tp_richcompare is defined */
    /// Availability: 2.*
    enum int Py_TPFLAGS_HAVE_RICHCOMPARE         = 1L<<5;
    /** Objects which are weakly referencable if their tp_weaklistoffset is >0 */
    /// Availability: 2.*
    enum int Py_TPFLAGS_HAVE_WEAKREFS            = 1L<<6;
    /** tp_iter is defined */
    /// Availability: 2.*
    enum int Py_TPFLAGS_HAVE_ITER                = 1L<<7;
    /** New members introduced by Python 2.2 exist */
    /// Availability: 2.*
    enum int Py_TPFLAGS_HAVE_CLASS               = 1L<<8;
}
/** Set if the type object is dynamically allocated */
enum int Py_TPFLAGS_HEAPTYPE                 = 1L<<9;
/** Set if the type allows subclassing */
enum int Py_TPFLAGS_BASETYPE                 = 1L<<10;
/** Set if the type is 'ready' -- fully initialized */
enum int Py_TPFLAGS_READY                    = 1L<<12;
/** Set while the type is being 'readied', to prevent recursive ready calls */
enum int Py_TPFLAGS_READYING                 = 1L<<13;
/** Objects support garbage collection (see objimp.h) */
enum int Py_TPFLAGS_HAVE_GC                  = 1L<<14;

// YYY: Should conditionalize for stackless:
//#ifdef STACKLESS
//#define Py_TPFLAGS_HAVE_STACKLESS_EXTENSION (3L<<15)
//#else
/// _
enum int Py_TPFLAGS_HAVE_STACKLESS_EXTENSION = 0;
//#endif
version(Python_3_0_Or_Later) {
}else version(Python_2_5_Or_Later){
    /** Objects support nb_index in PyNumberMethods */
    /// Availability: 2.*
    enum Py_TPFLAGS_HAVE_INDEX               = 1L<<17;
}
version(Python_2_6_Or_Later){
    /** Objects support type attribute cache */
    /// Availability: >= 2.6
    enum Py_TPFLAGS_HAVE_VERSION_TAG =  (1L<<18);
    /// ditto
    enum Py_TPFLAGS_VALID_VERSION_TAG =  (1L<<19);

    /** Type is abstract and cannot be instantiated */
    /// Availability: >= 2.6
    enum Py_TPFLAGS_IS_ABSTRACT = (1L<<20);

    version(Python_3_0_Or_Later) {
    }else {
        /** Has the new buffer protocol */
        /// Availability: 2.6,2.7
        enum Py_TPFLAGS_HAVE_NEWBUFFER = (1L<<21);
    }

    /** These flags are used to determine if a type is a subclass. */
    /// Availability: >= 2.6
    enum Py_TPFLAGS_INT_SUBCLASS         =(1L<<23);
    /// ditto
    enum Py_TPFLAGS_LONG_SUBCLASS        =(1L<<24);
    /// ditto
    enum Py_TPFLAGS_LIST_SUBCLASS        =(1L<<25);
    /// ditto
    enum Py_TPFLAGS_TUPLE_SUBCLASS       =(1L<<26);
    /// ditto
    version(Python_3_0_Or_Later) {
        enum Py_TPFLAGS_BYTES_SUBCLASS      =(1L<<27);
    }else{
        enum Py_TPFLAGS_STRING_SUBCLASS      =(1L<<27);
    }
    /// ditto
    enum Py_TPFLAGS_UNICODE_SUBCLASS     =(1L<<28);
    /// ditto
    enum Py_TPFLAGS_DICT_SUBCLASS        =(1L<<29);
    /// ditto
    enum Py_TPFLAGS_BASE_EXC_SUBCLASS    =(1L<<30);
    /// ditto
    enum Py_TPFLAGS_TYPE_SUBCLASS        =(1L<<31);
}

version(Python_3_0_Or_Later) {
    /// _
    enum Py_TPFLAGS_DEFAULT = Py_TPFLAGS_HAVE_STACKLESS_EXTENSION |
        Py_TPFLAGS_HAVE_VERSION_TAG;
}else version(Python_2_5_Or_Later){
    /// _
    enum Py_TPFLAGS_DEFAULT =
        Py_TPFLAGS_HAVE_GETCHARBUFFER |
        Py_TPFLAGS_HAVE_SEQUENCE_IN |
        Py_TPFLAGS_HAVE_INPLACEOPS |
        Py_TPFLAGS_HAVE_RICHCOMPARE |
        Py_TPFLAGS_HAVE_WEAKREFS |
        Py_TPFLAGS_HAVE_ITER |
        Py_TPFLAGS_HAVE_CLASS |
        Py_TPFLAGS_HAVE_STACKLESS_EXTENSION |
        Py_TPFLAGS_HAVE_INDEX |
        0
        ;
    version(Python_2_6_Or_Later) {
        // meh
        enum Py_TPFLAGS_DEFAULT_EXTERNAL = Py_TPFLAGS_DEFAULT;
    }
}else{
    /// _
    enum int Py_TPFLAGS_DEFAULT =
        Py_TPFLAGS_HAVE_GETCHARBUFFER |
        Py_TPFLAGS_HAVE_SEQUENCE_IN |
        Py_TPFLAGS_HAVE_INPLACEOPS |
        Py_TPFLAGS_HAVE_RICHCOMPARE |
        Py_TPFLAGS_HAVE_WEAKREFS |
        Py_TPFLAGS_HAVE_ITER |
        Py_TPFLAGS_HAVE_CLASS |
        Py_TPFLAGS_HAVE_STACKLESS_EXTENSION |
        0
        ;
}

// D translation of C macro:
/// _
int PyType_HasFeature()(PyTypeObject* t, int f) {
    version(Python_3_2_Or_Later) {
        return (PyType_GetFlags(t) & f) != 0;
    }else{
        return (t.tp_flags & f) != 0;
    }
}

version(Python_2_6_Or_Later){
    alias PyType_HasFeature PyType_FastSubclass;
}

/**
Initializes reference counts to 1, and
in special builds (Py_REF_DEBUG, Py_TRACE_REFS) performs additional
bookkeeping appropriate to the special build.
*/
void _Py_NewReference()(PyObject* op) {
    Py_SET_REFCNT(op, 1);
}

/**
Increment reference counts.  Can be used wherever a void expression is allowed.
The argument must not be a NULL pointer. If it may be NULL, use
Py_XINCREF instead.

In addition, converts and returns Borrowed references to their base types.
*/
auto Py_INCREF(T)(T op)
if(is(T == PyObject*) || is(T _unused : Borrowed!P*, P))
{
    static if(is(T _unused : Borrowed!P*, P)) {
        PyObject* pop = cast(PyObject*) op;
        ++pop.ob_refcnt;
        return cast(P*) pop;
    }else {
        ++op.ob_refcnt;
    }
}

/**
Increment reference counts.  Can be used wherever a void expression is allowed.
The argument may be a NULL pointer.

In addition, converts and returns Borrowed references to their base types.
The argument may not be null.
*/
auto Py_XINCREF(T)(T op) {
    if (op == null) {
        //static if(is(typeof(return) == void))
        static if(is(typeof(Py_INCREF!T(op)) == void))
            return;
        else {
            assert(0, "INCREF on null");
        }
    }
    return Py_INCREF(op);
}

/**
Used to decrement reference counts. Calls the object's deallocator function
when the refcount falls to 0; for objects that don't contain references to
other objects or heap memory this can be the standard function free().
Can be used wherever a void expression is allowed.  The argument must not be a
NULL pointer.  If it may be NULL, use Py_XDECREF instead.
*/
void Py_DECREF()(PyObject *op) {
    // version(PY_REF_DEBUG) _Py_RefTotal++
    --op.ob_refcnt;

    // EMN: this is a horrible idea because it takes forever to figure out
    //      what's going on if this is being called from within the garbage
    //      collector.

    // EMN: if we do keep it, don't change the assert!
    // assert(0) or assert(condition) mess up linking somehow.
    if(op.ob_refcnt < 0) assert (0, "refcount negative");
    if(op.ob_refcnt != 0) {
        // version(PY_REF_DEBUG) _Py_NegativeRefcount(__FILE__, __LINE__, cast(PyObject*)op);
    }else {
        op.ob_type.tp_dealloc(op);
    }
}

/** Same as Py_DECREF, except is a no-op if op is null.
  */
void Py_XDECREF()(PyObject* op)
{
    if(op == null) {
        return;
    }

    Py_DECREF(op);
}

/**
These are provided as conveniences to Python runtime embedders, so that
they can have object code that is not dependent on Python compilation flags.
*/
void Py_IncRef(PyObject *);
/// ditto
void Py_DecRef(PyObject *);

mixin(PyAPI_DATA!"PyObject _Py_NoneStruct");

// issue 8683 gets in the way of this being a property
Borrowed!PyObject* Py_None()() {
    return borrowed(&_Py_NoneStruct);
}
/** Rich comparison opcodes */
enum Py_LT = 0;
/// ditto
enum Py_LE = 1;
/// ditto
enum Py_EQ = 2;
/// ditto
enum Py_NE = 3;
/// ditto
enum Py_GT = 4;
/// ditto
enum Py_GE = 5;

version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    void _Py_Dealloc(PyObject*);
}
