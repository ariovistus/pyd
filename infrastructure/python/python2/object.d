module python2.object;

import std.c.stdio;
import python2.types;
import python2.methodobject;
import python2.structmember;
import python2.descrobject;

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
template _PyObject_HEAD_EXTRA() {}
/*}*/

template PyObject_HEAD() {
    mixin _PyObject_HEAD_EXTRA;
    Py_ssize_t ob_refcnt;
    PyTypeObject *ob_type;
}

struct PyObject {
    mixin PyObject_HEAD;
}

/++++ Not part of Python api!!! ++++/
// Convention: borrowed PyObject* is cast to PyObject_BorrowedRef*.
// Use Py_INIT to get PyObject* back.
struct Borrowed(T) { }
alias Borrowed!PyObject PyObject_BorrowedRef;
/++++ End Not part of Python api!!! ++++/

template PyObject_VAR_HEAD() {
    mixin PyObject_HEAD;
    Py_ssize_t ob_size; /* Number of items in variable part */
}

struct PyVarObject {
    mixin PyObject_VAR_HEAD;
}

auto Py_REFCNT()(PyObject* ob){ return ob.ob_refcnt; }
auto Py_TYPE()(PyObject* ob){ return ob.ob_type; }
auto Py_SIZE()(PyVarObject* ob){ return ob.ob_size; }

alias PyObject* function(PyObject*) unaryfunc;
alias PyObject* function(PyObject*, PyObject*) binaryfunc;
alias PyObject* function(PyObject*, PyObject*, PyObject*) ternaryfunc;
alias Py_ssize_t function(PyObject*) lenfunc;
alias lenfunc inquiry;
alias int function(PyObject**, PyObject**) coercion;
alias PyObject* function(PyObject*, Py_ssize_t) ssizeargfunc;
alias PyObject* function(PyObject*, Py_ssize_t, Py_ssize_t) ssizessizeargfunc;
version(Python_2_5_Or_Later){
}else{
    alias ssizeargfunc intargfunc;
    alias ssizessizeargfunc intintargfunc;
}
alias int function(PyObject*, Py_ssize_t, PyObject*) ssizeobjargproc;
alias int function(PyObject*, Py_ssize_t, Py_ssize_t, PyObject*) ssizessizeobjargproc;
version(Python_2_5_Or_Later){
}else{
    alias ssizeobjargproc intobjargproc;
    alias ssizessizeobjargproc intintobjargproc;
}
alias int function(PyObject*, PyObject*, PyObject*) objobjargproc;

// ssize_t-based buffer interface
alias Py_ssize_t function(PyObject*, Py_ssize_t, void**) readbufferproc;
alias Py_ssize_t function(PyObject*, Py_ssize_t, void**) writebufferproc;
alias Py_ssize_t function(PyObject*, Py_ssize_t*) segcountproc;
alias Py_ssize_t function(PyObject*, Py_ssize_t, char**) charbufferproc;
version(Python_2_5_Or_Later){
}else{
    // int-based buffer interface
    alias readbufferproc getreadbufferproc;
    alias writebufferproc getwritebufferproc;
    alias segcountproc getsegcountproc;
    alias charbufferproc getcharbufferproc;
}

version(Python_2_6_Or_Later){
    /* Py3k buffer interface */

    struct Py_buffer{
        void* buf;
        PyObject* obj;        /* borrowed reference */
        Py_ssize_t len;
        Py_ssize_t itemsize;  /* This is Py_ssize_t so it can be
                                 pointed to by strides in simple case.*/
        int readonly;
        int ndim;
        char* format;
        Py_ssize_t* shape;
        Py_ssize_t* strides;
        Py_ssize_t* suboffsets;
        void* internal;
    };

    alias int function(PyObject*, Py_buffer*, int) getbufferproc;
    alias void function(PyObject*, Py_buffer*) releasebufferproc;

    /* Flags for getting buffers */
    enum PyBUF_SIMPLE = 0;
    enum PyBUF_WRITABLE = 0x0001;
    /*  we used to include an E, backwards compatible alias  */
    enum PyBUF_WRITEABLE = PyBUF_WRITABLE;
    enum PyBUF_FORMAT = 0x0004;
    enum PyBUF_ND = 0x0008;
    enum PyBUF_STRIDES = (0x0010 | PyBUF_ND);
    enum PyBUF_C_CONTIGUOUS = (0x0020 | PyBUF_STRIDES);
    enum PyBUF_F_CONTIGUOUS = (0x0040 | PyBUF_STRIDES);
    enum PyBUF_ANY_CONTIGUOUS = (0x0080 | PyBUF_STRIDES);
    enum PyBUF_INDIRECT = (0x0100 | PyBUF_STRIDES);

    enum PyBUF_CONTIG = (PyBUF_ND | PyBUF_WRITABLE);
    enum PyBUF_CONTIG_RO = (PyBUF_ND);

    enum PyBUF_STRIDED = (PyBUF_STRIDES | PyBUF_WRITABLE);
    enum PyBUF_STRIDED_RO = (PyBUF_STRIDES);

    enum PyBUF_RECORDS = (PyBUF_STRIDES | PyBUF_WRITABLE | PyBUF_FORMAT);
    enum PyBUF_RECORDS_RO = (PyBUF_STRIDES | PyBUF_FORMAT);

    enum PyBUF_FULL = (PyBUF_INDIRECT | PyBUF_WRITABLE | PyBUF_FORMAT);
    enum PyBUF_FULL_RO = (PyBUF_INDIRECT | PyBUF_FORMAT);


    enum PyBUF_READ  = 0x100;
    enum PyBUF_WRITE = 0x200;
    enum PyBUF_SHADOW = 0x400;
    /* end Py3k buffer interface */
}

alias int function(PyObject*, PyObject*) objobjproc;
alias int function(PyObject*, void*) visitproc;
alias int function(PyObject*, visitproc, void*) traverseproc;

// Python-header-file: Include/object.h:
struct PyNumberMethods {
    binaryfunc nb_add;
    binaryfunc nb_subtract;
    binaryfunc nb_multiply;
    binaryfunc nb_divide;
    binaryfunc nb_remainder;
    binaryfunc nb_divmod;
    ternaryfunc nb_power;
    unaryfunc nb_negative;
    unaryfunc nb_positive;
    unaryfunc nb_absolute;
    inquiry nb_nonzero;
    unaryfunc nb_invert;
    binaryfunc nb_lshift;
    binaryfunc nb_rshift;
    binaryfunc nb_and;
    binaryfunc nb_xor;
    binaryfunc nb_or;
    coercion nb_coerce;
    unaryfunc nb_int;
    unaryfunc nb_long;
    unaryfunc nb_float;
    unaryfunc nb_oct;
    unaryfunc nb_hex;

    binaryfunc nb_inplace_add;
    binaryfunc nb_inplace_subtract;
    binaryfunc nb_inplace_multiply;
    binaryfunc nb_inplace_divide;
    binaryfunc nb_inplace_remainder;
    ternaryfunc nb_inplace_power;
    binaryfunc nb_inplace_lshift;
    binaryfunc nb_inplace_rshift;
    binaryfunc nb_inplace_and;
    binaryfunc nb_inplace_xor;
    binaryfunc nb_inplace_or;

    binaryfunc nb_floor_divide;
    binaryfunc nb_true_divide;
    binaryfunc nb_inplace_floor_divide;
    binaryfunc nb_inplace_true_divide;

    version(Python_2_5_Or_Later){
        unaryfunc nb_index;
    }
}

struct PySequenceMethods {
    lenfunc sq_length;
    binaryfunc sq_concat;
    ssizeargfunc sq_repeat;
    ssizeargfunc sq_item;
    ssizessizeargfunc sq_slice;
    ssizeobjargproc sq_ass_item;
    ssizessizeobjargproc sq_ass_slice;
    objobjproc sq_contains;
    binaryfunc sq_inplace_concat;
    ssizeargfunc sq_inplace_repeat;
}

struct PyMappingMethods {
    lenfunc mp_length;
    binaryfunc mp_subscript;
    objobjargproc mp_ass_subscript;
}

struct PyBufferProcs {
    readbufferproc bf_getreadbuffer;
    writebufferproc bf_getwritebuffer;
    segcountproc bf_getsegcount;
    charbufferproc bf_getcharbuffer;
    version(Python_2_6_Or_Later){
        getbufferproc bf_getbuffer;
        releasebufferproc bf_releasebuffer;
    }
}


alias void function(void*) freefunc;
alias void function(PyObject*) destructor;
alias int function(PyObject*, FILE*, int) printfunc;
alias PyObject* function(PyObject*, char*) getattrfunc;
alias PyObject* function(PyObject*, PyObject*) getattrofunc;
alias int function(PyObject*, char*, PyObject*) setattrfunc;
alias int function(PyObject*, PyObject*, PyObject*) setattrofunc;
alias int function(PyObject*, PyObject*) cmpfunc;
alias PyObject* function(PyObject*) reprfunc;
alias C_long function(PyObject*) hashfunc;
alias PyObject* function(PyObject*, PyObject*, int) richcmpfunc;
alias PyObject* function(PyObject*) getiterfunc;
alias PyObject* function(PyObject*) iternextfunc;
alias PyObject* function(PyObject*, PyObject*, PyObject*) descrgetfunc;
alias int function(PyObject*, PyObject*, PyObject*) descrsetfunc;
alias int function(PyObject*, PyObject*, PyObject*) initproc;
alias PyObject* function(PyTypeObject*, PyObject*, PyObject*) newfunc;
alias PyObject* function(PyTypeObject*, Py_ssize_t) allocfunc;

struct PyTypeObject {
    mixin PyObject_VAR_HEAD;

    Char1* tp_name;
    Py_ssize_t tp_basicsize, tp_itemsize;

    destructor tp_dealloc;
    printfunc tp_print;
    getattrfunc tp_getattr;
    setattrfunc tp_setattr;
    cmpfunc tp_compare;
    reprfunc tp_repr;

    PyNumberMethods* tp_as_number;
    PySequenceMethods* tp_as_sequence;
    PyMappingMethods* tp_as_mapping;

    hashfunc tp_hash;
    ternaryfunc tp_call;
    reprfunc tp_str;
    getattrofunc tp_getattro;
    setattrofunc tp_setattro;

    PyBufferProcs* tp_as_buffer;

    C_long tp_flags;

    Char1* tp_doc;

    traverseproc tp_traverse;

    inquiry tp_clear;

    richcmpfunc tp_richcompare;

    version(Python_2_5_Or_Later){
        Py_ssize_t tp_weaklistoffset;
    }else{
        C_long tp_weaklistoffset;
    }

    getiterfunc tp_iter;
    iternextfunc tp_iternext;

    PyMethodDef* tp_methods;
    PyMemberDef* tp_members;
    PyGetSetDef* tp_getset;
    PyTypeObject* tp_base;
    PyObject* tp_dict;
    descrgetfunc tp_descr_get;
    descrsetfunc tp_descr_set;
    version(Python_2_5_Or_Later){
        Py_ssize_t tp_dictoffset;
    }else{
        C_long tp_dictoffset;
    }
    initproc tp_init;
    allocfunc tp_alloc;
    newfunc tp_new;
    freefunc tp_free;
    inquiry tp_is_gc;
    PyObject* tp_bases;
    PyObject* tp_mro;
    PyObject* tp_cache;
    PyObject* tp_subclasses;
    PyObject* tp_weaklist;
    destructor tp_del;
    version(Python_2_6_Or_Later){
        /* Type attribute cache version tag. Added in version 2.6 */
        uint tp_version_tag;
    }
}

struct PyHeapTypeObject {
    version(Python_2_5_Or_Later){
        PyTypeObject ht_type;
    }else{
        PyTypeObject type;
    }
    PyNumberMethods as_number;
    PyMappingMethods as_mapping;
    PySequenceMethods as_sequence;
    PyBufferProcs as_buffer;
    version(Python_2_5_Or_Later){
        PyObject* ht_name;
        PyObject* ht_slots;
    }else{
        PyObject* name;
        PyObject* slots;
    }
}

int PyType_IsSubtype(PyTypeObject *, PyTypeObject *);

// D translation of C macro:
int PyObject_TypeCheck()(PyObject *ob, PyTypeObject *tp) {
    return (ob.ob_type == tp || PyType_IsSubtype(ob.ob_type, tp));
}

/* Note that this Python support module makes pointers to PyType_Type and
 * other global variables exposed by the Python API available to D
 * programmers indirectly (see this module's static initializer). */

// D translation of C macro:
int PyType_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, PyType_Type_p);
}
// D translation of C macro:
int PyType_CheckExact()(PyObject *op) {
    return op.ob_type == PyType_Type_p;
}

int PyType_Ready(PyTypeObject *);
PyObject * PyType_GenericAlloc(PyTypeObject *, Py_ssize_t);
PyObject * PyType_GenericNew(PyTypeObject *, PyObject *, PyObject *);
version(Python_2_6_Or_Later){
    uint PyType_ClearCache();
    void PyType_Modified(PyTypeObject *);
}


int PyObject_Print(PyObject *, FILE *, int);
PyObject * PyObject_Repr(PyObject *);
PyObject * PyObject_Str(PyObject *);

version(Python_2_6_Or_Later){
    alias PyObject_Str PyObject_Bytes;
}

PyObject * PyObject_Unicode(PyObject *);

int PyObject_Compare(PyObject *, PyObject *);
PyObject * PyObject_RichCompare(PyObject *, PyObject *, int);
int PyObject_RichCompareBool(PyObject *, PyObject *, int);
PyObject * PyObject_GetAttrString(PyObject *, Char1 *);
int PyObject_SetAttrString(PyObject *, Char1 *, PyObject *);
int PyObject_HasAttrString(PyObject *, Char1 *);
PyObject * PyObject_GetAttr(PyObject *, PyObject *);
int PyObject_SetAttr(PyObject *, PyObject *, PyObject *);
int PyObject_HasAttr(PyObject *, PyObject *);
PyObject * PyObject_SelfIter(PyObject *);
PyObject * PyObject_GenericGetAttr(PyObject *, PyObject *);
int PyObject_GenericSetAttr(PyObject *,
        PyObject *, PyObject *);
C_long PyObject_Hash(PyObject *);
version(Python_2_6_Or_Later){
    C_long PyObject_HashNotImplemented(PyObject *);
}
int PyObject_IsTrue(PyObject *);
int PyObject_Not(PyObject *);
//int PyCallable_Check(PyObject *);
int PyNumber_Coerce(PyObject **, PyObject **);
int PyNumber_CoerceEx(PyObject **, PyObject **);

void PyObject_ClearWeakRefs(PyObject *);

PyObject * PyObject_Dir(PyObject *);

int Py_ReprEnter(PyObject *);
void Py_ReprLeave(PyObject *);

enum int Py_PRINT_RAW = 1;


enum int Py_TPFLAGS_HAVE_GETCHARBUFFER       = 1L<<0;
enum int Py_TPFLAGS_HAVE_SEQUENCE_IN         = 1L<<1;
enum int Py_TPFLAGS_GC                       = 0;
enum int Py_TPFLAGS_HAVE_INPLACEOPS          = 1L<<3;
enum int Py_TPFLAGS_CHECKTYPES               = 1L<<4;
enum int Py_TPFLAGS_HAVE_RICHCOMPARE         = 1L<<5;
enum int Py_TPFLAGS_HAVE_WEAKREFS            = 1L<<6;
enum int Py_TPFLAGS_HAVE_ITER                = 1L<<7;
enum int Py_TPFLAGS_HAVE_CLASS               = 1L<<8;
enum int Py_TPFLAGS_HEAPTYPE                 = 1L<<9;
enum int Py_TPFLAGS_BASETYPE                 = 1L<<10;
enum int Py_TPFLAGS_READY                    = 1L<<12;
enum int Py_TPFLAGS_READYING                 = 1L<<13;
enum int Py_TPFLAGS_HAVE_GC                  = 1L<<14;

// YYY: Should conditionalize for stackless:
//#ifdef STACKLESS
//#define Py_TPFLAGS_HAVE_STACKLESS_EXTENSION (3L<<15)
//#else
enum int Py_TPFLAGS_HAVE_STACKLESS_EXTENSION = 0;
//#endif
version(Python_2_5_Or_Later){
    enum Py_TPFLAGS_HAVE_INDEX               = 1L<<17;
}
version(Python_2_6_Or_Later){
    /* Objects support type attribute cache */
    enum Py_TPFLAGS_HAVE_VERSION_TAG =  (1L<<18);
    enum Py_TPFLAGS_VALID_VERSION_TAG =  (1L<<19);

    /* Type is abstract and cannot be instantiated */
    enum Py_TPFLAGS_IS_ABSTRACT = (1L<<20);

    /* Has the new buffer protocol */
    enum Py_TPFLAGS_HAVE_NEWBUFFER = (1L<<21);

    /* These flags are used to determine if a type is a subclass. */
    enum Py_TPFLAGS_INT_SUBCLASS         =(1L<<23);
    enum Py_TPFLAGS_LONG_SUBCLASS        =(1L<<24);
    enum Py_TPFLAGS_LIST_SUBCLASS        =(1L<<25);
    enum Py_TPFLAGS_TUPLE_SUBCLASS       =(1L<<26);
    enum Py_TPFLAGS_STRING_SUBCLASS      =(1L<<27);
    enum Py_TPFLAGS_UNICODE_SUBCLASS     =(1L<<28);
    enum Py_TPFLAGS_DICT_SUBCLASS        =(1L<<29);
    enum Py_TPFLAGS_BASE_EXC_SUBCLASS    =(1L<<30);
    enum Py_TPFLAGS_TYPE_SUBCLASS        =(1L<<31);
}

version(Python_2_5_Or_Later){
    enum int Py_TPFLAGS_DEFAULT =
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
    version(Python_2_6_Or_Later){
        // meh
        enum Py_TPFLAGS_DEFAULT_EXTERNAL = Py_TPFLAGS_DEFAULT;
    }
}else{
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
int PyType_HasFeature()(PyTypeObject *t, int f) {
    return (t.tp_flags & f) != 0;
}

version(Python_2_6_Or_Later){
    alias PyType_HasFeature PyType_FastSubclass;
}

auto Py_INCREF(T)(T op) 
if(is(T == PyObject*) || is(T == PyObject_BorrowedRef*))
{
    static if(is(T == PyObject_BorrowedRef*)) {
        PyObject* pop = cast(PyObject*) op;
        ++pop.ob_refcnt;
        return pop;
    }else {
        ++op.ob_refcnt;
    }
}

auto Py_XINCREF(T)(T op) {
    if (op == null) {
        static if(is(typeof(return) == void))
            return;
        else {
            import std.exception;
            enforce(0, "INCREF on null");
        }
    }
    return Py_INCREF(op);
}

void Py_DECREF()(PyObject *op) {
    // version(PY_REF_DEBUG) _Py_RefTotal++
    --op.ob_refcnt;

    // EMN: this is a horrible idea because it takes forever to figure out 
    //      what's going on if this is being called from within the garbage 
    //      collector.
    assert (op.ob_refcnt >= 0);
    if(op.ob_refcnt != 0) {
        // version(PY_REF_DEBUG) _Py_NegativeRefcount(__FILE__, __LINE__, cast(PyObject*)op);
    }else {
        op.ob_type.tp_dealloc(op);
    }
}

void Py_XDECREF()(PyObject* op)
{
    if(op == null) {
        return;
    }

    Py_DECREF(op);
}

void Py_IncRef(PyObject *);
void Py_DecRef(PyObject *);

/* Rich comparison opcodes */
enum int Py_LT = 0;
enum int Py_LE = 1;
enum int Py_EQ = 2;
enum int Py_NE = 3;
enum int Py_GT = 4;
enum int Py_GE = 5;

