/* DSR:2005.10.26.16.28:
// Ellery Newcomer is going to make this THE python header for 2.4 thru 2.7.
// yuck.

XXX:

- In a build process controlled by Python distutils, need to detect whether the
  Python interpreter was built in debug build mode, and if so, make the
  appropriate adjustments to the header mixins.

*/

/**
Contains all relevant definitions from python/Include

When issue 7758 is resolved, we will have this module split into
separate files to match python/Include (and all defs will show up in ddoc)
*/
module python;

// here's what we like
version(Python_2_7_Or_Later){
}else version(Python_2_6_Or_Later){
}else version(Python_2_5_Or_Later){
}else version(Python_2_4_Or_Later){
}else{
    static assert(false,"Python version not specified!");
}
/+
version (build) {
    version (DigitalMars) {
        version (Windows) {
            pragma(link, "python25_digitalmars");
        }
    } else {
        pragma(link, "python2.5");
    }
}

version (Tango) {
    import tango.stdc.stdio;
    import tango.stdc.time;
    import tango.stdc.string;
} else {+/
    import std.c.stdio;
    import std.c.time;
    import std.c.string;
    import std.string: toStringz;
//}


/* D long is always 64 bits, but when the Python/C API mentions long, it is of
 * course referring to the C type long, the size of which is 32 bits on both
 * X86 and X86_64 under Windows, but 32 bits on X86 and 64 bits on X86_64 under
 * most other operating systems. */

alias long C_longlong;
alias ulong C_ulonglong;

version(Windows) {
  alias int C_long;
  alias uint C_ulong;
} else {
  version (X86) {
    alias int C_long;
    alias uint C_ulong;
  } else {
    alias long C_long;
    alias ulong C_ulong;
  }
}


/*
 * Py_ssize_t is defined as a signed type which is 8 bytes on X86_64 and 4
 * bytes on X86.
 */
version(Python_2_5_Or_Later){
    version (X86_64) {
        alias long Py_ssize_t;
    } else {
        alias int Py_ssize_t;
    }
}else {
    /*
     * Seems Py_ssize_t didn't exist in 2.4, and int was everywhere it is now.
     */
    alias int Py_ssize_t;
}

extern (C) {
///////////////////////////////////////////////////////////////////////////////
// PYTHON DATA STRUCTURES AND ALIASES
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/Python.h:
  enum int Py_single_input = 256;
  enum int Py_file_input = 257;
  enum int Py_eval_input = 258;

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

  /+-++ Not part of Python api!!! ++++/
  /**
    Denotes a borrowed reference.

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
  struct Borrowed(T) {
  }

  /**
  Convert a python reference to borrowed reference.
  */
  Borrowed!T* borrowed(T)(T* obj) {
    return cast(Borrowed!T*) obj;
  }
  alias Borrowed!PyObject PyObject_BorrowedRef;

  /+-++ End Not part of Python api!!! ++++/

  template PyObject_VAR_HEAD() {
    mixin PyObject_HEAD;
    Py_ssize_t ob_size; /* Number of items in variable part */
  }

  struct PyVarObject {
    mixin PyObject_VAR_HEAD;
  }

  version(Python_2_6_Or_Later){
      auto Py_REFCNT()(PyObject* ob){ return ob.ob_refcnt; }
      auto Py_TYPE()(PyObject* ob){ return ob.ob_type; }
      auto Py_SIZE()(PyVarObject* ob){ return ob.ob_size; }
  }

  alias PyObject* function(PyObject *) unaryfunc;
  alias PyObject* function(PyObject *, PyObject *) binaryfunc;
  alias PyObject* function(PyObject *, PyObject *, PyObject *) ternaryfunc;
  alias Py_ssize_t function(PyObject *) lenfunc;
  alias lenfunc inquiry;
  alias int function(PyObject **, PyObject **) coercion;
  alias PyObject* function(PyObject *, Py_ssize_t) ssizeargfunc;
  alias PyObject* function(PyObject *, Py_ssize_t, Py_ssize_t) ssizessizeargfunc;
  version(Python_2_5_Or_Later){
  }else{
      alias ssizeargfunc intargfunc;
      alias ssizessizeargfunc intintargfunc;
  }
  alias int function(PyObject *, Py_ssize_t, PyObject *) ssizeobjargproc;
  alias int function(PyObject *, Py_ssize_t, Py_ssize_t, PyObject *) ssizessizeobjargproc;
  version(Python_2_5_Or_Later){
  }else{
      alias ssizeobjargproc intobjargproc;
      alias ssizessizeobjargproc intintobjargproc;
  }
  alias int function(PyObject *, PyObject *, PyObject *) objobjargproc;

  // ssize_t-based buffer interface
  alias Py_ssize_t function(PyObject *, Py_ssize_t, void **) readbufferproc;
  alias Py_ssize_t function(PyObject *, Py_ssize_t, void **) writebufferproc;
  alias Py_ssize_t function(PyObject *, Py_ssize_t *) segcountproc;
  alias Py_ssize_t function(PyObject *, Py_ssize_t, char **) charbufferproc;
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
          void *buf;
          Borrowed!PyObject *obj;        /* borrowed reference */
          Py_ssize_t len;
          Py_ssize_t itemsize;  /* This is Py_ssize_t so it can be
                                   pointed to by strides in simple case.*/
          int readonly;
          int ndim;
          char *format;
          Py_ssize_t *shape;
          Py_ssize_t *strides;
          Py_ssize_t *suboffsets;
          version(Python_2_7_Or_Later) {
              Py_ssize_t[2] smalltable;
          }
          void *internal;
      };

      alias int function(PyObject *, Py_buffer *, int) getbufferproc;
      alias void function(PyObject *, Py_buffer *) releasebufferproc;

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

  alias int function(PyObject *, PyObject *) objobjproc;
  alias int function(PyObject *, void *) visitproc;
  alias int function(PyObject *, visitproc, void *) traverseproc;

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
        /* Added in release 2.5 */
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


  alias void function(void *) freefunc;
  alias void function(PyObject *) destructor;
  alias int function(PyObject *, FILE *, int) printfunc;
  alias PyObject* function(PyObject *, char *) getattrfunc;
  alias PyObject* function(PyObject *, PyObject *) getattrofunc;
  alias int function(PyObject *, char *, PyObject *) setattrfunc;
  alias int function(PyObject *, PyObject *, PyObject *) setattrofunc;
  alias int function(PyObject *, PyObject *) cmpfunc;
  alias PyObject* function(PyObject *) reprfunc;
  alias C_long function(PyObject *) hashfunc;
  alias PyObject* function(PyObject *, PyObject *, int) richcmpfunc;
  alias PyObject* function(PyObject *) getiterfunc;
  alias PyObject* function(PyObject *) iternextfunc;
  alias PyObject* function(PyObject *, PyObject *, PyObject *) descrgetfunc;
  alias int function(PyObject *, PyObject *, PyObject *) descrsetfunc;
  alias int function(PyObject *, PyObject *, PyObject *) initproc;
  alias PyObject* function(PyTypeObject *, PyObject *, PyObject *) newfunc;
  alias PyObject* function(PyTypeObject *, Py_ssize_t) allocfunc;

  struct PyTypeObject {
    mixin PyObject_VAR_HEAD;

    Char1 *tp_name;
    Py_ssize_t tp_basicsize, tp_itemsize;

    destructor tp_dealloc;
    printfunc tp_print;
    getattrfunc tp_getattr;
    setattrfunc tp_setattr;
    cmpfunc tp_compare;
    reprfunc tp_repr;

    PyNumberMethods *tp_as_number;
    PySequenceMethods *tp_as_sequence;
    PyMappingMethods *tp_as_mapping;

    hashfunc tp_hash;
    ternaryfunc tp_call;
    reprfunc tp_str;
    getattrofunc tp_getattro;
    setattrofunc tp_setattro;

    PyBufferProcs *tp_as_buffer;

    C_long tp_flags;

    Char1 *tp_doc;

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

    PyMethodDef *tp_methods;
    PyMemberDef *tp_members;
    PyGetSetDef *tp_getset;
    PyTypeObject *tp_base;
    PyObject *tp_dict;
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
    PyObject *tp_bases;
    PyObject *tp_mro;
    PyObject *tp_cache;
    PyObject *tp_subclasses;
    PyObject *tp_weaklist;
    destructor tp_del;
    version(Python_2_6_Or_Later){
        /* Type attribute cache version tag. Added in version 2.6 */
        uint tp_version_tag;
    }
  }

  //alias _typeobject PyTypeObject;

  struct _heaptypeobject {
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
          PyObject *ht_name;
          PyObject *ht_slots;
      }else{
          PyObject *name;
          PyObject *slots;
      }
  }
  alias _heaptypeobject PyHeapTypeObject;


  // Python-header-file: Include/pymem.h:
  void * PyMem_Malloc(size_t);
  void * PyMem_Realloc(void *, size_t);
  void PyMem_Free(void *);


///////////////////////////////////////////////////////////////////////////////
// GENERIC TYPE CHECKING
///////////////////////////////////////////////////////////////////////////////

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


///////////////////////////////////////////////////////////////////////////////
// REFERENCE COUNTING
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/object.h:

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

  auto Py_XINCREF(T)(T op) {
    if (op == null) {
        static if(is(typeof(Py_INCREF!T(op)) == void))
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


///////////////////////////////////////////////////////////////////////////////////////////////
// UNICODE
///////////////////////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/unicodeobject.h:
      import std.c.stdarg: va_list;
  /* The Python header explains:
   *   Unicode API names are mangled to assure that UCS-2 and UCS-4 builds
   *   produce different external names and thus cause import errors in
   *   case Python interpreters and extensions with mixed compiled in
   *   Unicode width assumptions are combined. */


  version (Python_Unicode_UCS2) {
    version (Windows) {
      alias wchar Py_UNICODE;
    } else {
      alias ushort Py_UNICODE;
    }
  } else {
    alias uint Py_UNICODE;
  }

  struct PyUnicodeObject {
    mixin PyObject_HEAD;

    Py_ssize_t length;
    Py_UNICODE *str;
    C_long hash;
    PyObject *defenc;
  }

  // &PyUnicode_Type is accessible via PyUnicode_Type_p.
  // D translations of C macros:
  int PyUnicode_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, PyUnicode_Type_p);
  }
  int PyUnicode_CheckExact()(PyObject *op) {
    return op.ob_type == PyUnicode_Type_p;
  }

  size_t PyUnicode_GET_SIZE()(PyUnicodeObject *op) {
    return op.length;
  }
  size_t PyUnicode_GET_DATA_SIZE()(PyUnicodeObject *op) {
    return op.length * Py_UNICODE.sizeof;
  }
  Py_UNICODE *PyUnicode_AS_UNICODE()(PyUnicodeObject *op) {
    return op.str;
  }
  const(char) *PyUnicode_AS_DATA()(PyUnicodeObject *op) {
    return cast(const(char)*) op.str;
  }

  Py_UNICODE Py_UNICODE_REPLACEMENT_CHARACTER = 0xFFFD;

version(Python_Unicode_UCS2) {
    enum PyUnicode_ = "PyUnicodeUCS2_";
}else{
    enum PyUnicode_ = "PyUnicodeUCS4_";
}

/*
   this function takes defs PyUnicode_XX and transforms them to
   PyUnicodeUCS4_XX();
   alias PyUnicodeUCS4_XX PyUnicode_XX;

   */
string substitute_and_alias()(string code) {
    import std.algorithm;
    import std.array;
    string[] newcodes;
LOOP:
    while(true) {
        if(startsWith(code,"/*")) {
            size_t comm_end_index = countUntil(code[2 .. $], "*/");
            if(comm_end_index == -1) break;
            newcodes ~= code[0 .. comm_end_index];
            code = code[comm_end_index .. $];
            continue;
        }
        if(!(startsWith(code,"PyUnicode_") || startsWith(code,"_PyUnicode"))) {
            size_t index = 0;
            while(index < code.length) {
                if(code[index] == '_') {
                    if(startsWith(code[index .. $], "_PyUnicode_")) {
                        break;
                    }
                }else if(code[index] == 'P') {
                    if(startsWith(code[index .. $], "PyUnicode_")) {
                        break;
                    }
                }else if(code[index] == '/') {
                    if(startsWith(code[index .. $], "/*")) {
                        break;
                    }
                }
                index++;
            }
            if(index == code.length) break;
            newcodes ~= code[0 .. index];
            code = code[index .. $];
            continue;
        }
        size_t end_index = countUntil(code, "(");
        if(end_index == -1) break;
        string alias_name = code[0 .. end_index];
        string func_name = replace(alias_name, "PyUnicode_", PyUnicode_);
        size_t index0 = end_index+1;
        int parencount = 1;
        while(parencount && index0 < code.length) {
            if(startsWith(code[index0 .. $], "/*")) {
                size_t comm_end_index = countUntil(code[index0+2 .. $], "*/");
                if(comm_end_index == -1) break LOOP;
                index0 += comm_end_index;
                continue;
            }else if(code[index0] == '(') {
                parencount++;
                index0++;
            }else if(code[index0] == ')') {
                parencount--;
                index0++;
            }else{
                index0++;
            }
        }
        size_t semi = countUntil(code[index0 .. $], ";");
        if(semi == -1) break;
        index0 += semi+1;

        string alias_line = "\nalias " ~ func_name ~ " " ~ alias_name ~ ";\n";
        newcodes ~= func_name;
        newcodes ~= code[end_index .. index0];
        newcodes ~= alias_line;

        code = code[index0 .. $];
    }

    string newcode;
    foreach(c; newcodes) {
        newcode ~= c;
    }
    return newcode;
}

enum string unicode_funs = q{
    version(Python_2_6_Or_Later) {

      /* Similar to PyUnicode_FromUnicode(), but u points to Latin-1 encoded bytes */
      PyObject* PyUnicode_FromStringAndSize(
              const(char)* u,        /* char buffer */
              Py_ssize_t size       /* size of buffer */
              );

      /* Similar to PyUnicode_FromUnicode(), but u points to null-terminated
         Latin-1 encoded bytes */
      PyObject* PyUnicode_FromString(
              const(char)* u        /* string */
              );
      PyObject* PyUnicode_FromFormatV(const(char)*, va_list);
      PyObject* PyUnicode_FromFormat(const(char)*, ...);

      /* Format the object based on the format_spec, as defined in PEP 3101
         (Advanced String Formatting). */
      PyObject * _PyUnicode_FormatAdvanced(PyObject *obj,
              Py_UNICODE *format_spec,
              Py_ssize_t format_spec_len);
      int PyUnicode_ClearFreeList();
      PyObject* PyUnicode_DecodeUTF7Stateful(
              const(char)* string,         /* UTF-7 encoded string */
              Py_ssize_t length,          /* size of string */
              const(char)* errors,         /* error handling */
              Py_ssize_t * consumed        /* bytes consumed */
              );
      PyObject* PyUnicode_DecodeUTF32(
              const(char)* string,         /* UTF-32 encoded string */
              Py_ssize_t length,          /* size of string */
              const(char)* errors,         /* error handling */
              int *byteorder              /* pointer to byteorder to use
                                             0=native;-1=LE,1=BE; updated on
                                             exit */
              );

      PyObject* PyUnicode_DecodeUTF32Stateful(
              const(char)*string,         /* UTF-32 encoded string */
              Py_ssize_t length,          /* size of string */
              const(char)*errors,         /* error handling */
              int *byteorder,             /* pointer to byteorder to use
                                             0=native;-1=LE,1=BE; updated on
                                             exit */
              Py_ssize_t *consumed        /* bytes consumed */
              );
      /* Returns a Python string using the UTF-32 encoding in native byte
         order. The string always starts with a BOM mark.  */

      PyObject* PyUnicode_AsUTF32String(
              PyObject *unicode           /* Unicode object */
              );

      /* Returns a Python string object holding the UTF-32 encoded value of
         the Unicode data.

         If byteorder is not 0, output is written according to the following
         byte order:

         byteorder == -1: little endian
         byteorder == 0:  native byte order (writes a BOM mark)
         byteorder == 1:  big endian

         If byteorder is 0, the output string will always start with the
         Unicode BOM mark (U+FEFF). In the other two modes, no BOM mark is
         prepended.

       */

      PyObject* PyUnicode_EncodeUTF32(
              const Py_UNICODE *data,     /* Unicode char buffer */
              Py_ssize_t length,          /* number of Py_UNICODE chars to encode */
              const(char)*errors,         /* error handling */
              int byteorder               /* byteorder to use 0=BOM+native;-1=LE,1=BE */
              );
      }

    PyObject *PyUnicode_FromUnicode(Py_UNICODE *u, Py_ssize_t size);
    Py_UNICODE *PyUnicode_AsUnicode(PyObject *unicode);
    Py_ssize_t PyUnicode_GetSize(PyObject *unicode);
    Py_UNICODE PyUnicode_GetMax();

    int PyUnicode_Resize(PyObject **unicode, Py_ssize_t length);
    PyObject *PyUnicode_FromEncodedObject(PyObject *obj, const(char) *encoding, const(char) *errors);
    PyObject *PyUnicode_FromObject(PyObject *obj);

    PyObject *PyUnicode_FromWideChar(const(wchar) *w, Py_ssize_t size);
    Py_ssize_t PyUnicode_AsWideChar(PyUnicodeObject *unicode, const(wchar) *w, Py_ssize_t size);

    PyObject *PyUnicode_FromOrdinal(int ordinal);

    PyObject *_PyUnicode_AsDefaultEncodedString(PyObject *, const(char)*);

    const(char)*PyUnicode_GetDefaultEncoding();
    int PyUnicode_SetDefaultEncoding(const(char)*encoding);

    PyObject *PyUnicode_Decode(const(char) *s, Py_ssize_t size, const(char) *encoding, const(char) *errors);
    PyObject *PyUnicode_Encode(Py_UNICODE *s, Py_ssize_t size, const(char) *encoding, const(char) *errors);
    PyObject *PyUnicode_AsEncodedObject(PyObject *unicode, const(char) *encoding, const(char) *errors);
    PyObject *PyUnicode_AsEncodedString(PyObject *unicode, const(char) *encoding, const(char) *errors);

    PyObject *PyUnicode_DecodeUTF7(const(char) *string, Py_ssize_t length, const(char) *errors);
    PyObject *PyUnicode_EncodeUTF7(Py_UNICODE *data, Py_ssize_t length,
        int encodeSetO, int encodeWhiteSpace, const(char) *errors
      );

    PyObject *PyUnicode_DecodeUTF8(const(char) *string, Py_ssize_t length, const(char) *errors);
    PyObject *PyUnicode_DecodeUTF8Stateful(const(char) *string, Py_ssize_t length,
        const(char) *errors, Py_ssize_t *consumed
      );
    PyObject *PyUnicode_AsUTF8String(PyObject *unicode);
    PyObject *PyUnicode_EncodeUTF8(Py_UNICODE *data, Py_ssize_t length, const(char) *errors);

    PyObject *PyUnicode_DecodeUTF16(const(char) *string, Py_ssize_t length, const(char) *errors, int *byteorder);
    PyObject *PyUnicode_DecodeUTF16Stateful(const(char) *string, Py_ssize_t length,
        const(char) *errors, int *byteorder, Py_ssize_t *consumed
      );
    PyObject *PyUnicode_AsUTF16String(PyObject *unicode);
    PyObject *PyUnicode_EncodeUTF16(Py_UNICODE *data, Py_ssize_t length,
        const(char) *errors, int byteorder
      );

    PyObject *PyUnicode_DecodeUnicodeEscape(const(char) *string, Py_ssize_t length, const(char) *errors);
    PyObject *PyUnicode_AsUnicodeEscapeString(PyObject *unicode);
    PyObject *PyUnicode_EncodeUnicodeEscape(Py_UNICODE *data, Py_ssize_t length);
    PyObject *PyUnicode_DecodeRawUnicodeEscape(const(char) *string, Py_ssize_t length, const(char) *errors);
    PyObject *PyUnicode_AsRawUnicodeEscapeString(PyObject *unicode);
    PyObject *PyUnicode_EncodeRawUnicodeEscape(Py_UNICODE *data, Py_ssize_t length);

    PyObject *_PyUnicode_DecodeUnicodeInternal(const(char) *string, Py_ssize_t length, const(char) *errors);

    PyObject *PyUnicode_DecodeLatin1(const(char) *string, Py_ssize_t length, const(char) *errors);
    PyObject *PyUnicode_AsLatin1String(PyObject *unicode);
    PyObject *PyUnicode_EncodeLatin1(Py_UNICODE *data, Py_ssize_t length, const(char) *errors);

    PyObject *PyUnicode_DecodeASCII(const(char) *string, Py_ssize_t length, const(char) *errors);
    PyObject *PyUnicode_AsASCIIString(PyObject *unicode);
    PyObject *PyUnicode_EncodeASCII(Py_UNICODE *data, Py_ssize_t length, const(char) *errors);

    PyObject *PyUnicode_DecodeCharmap(const(char) *string, Py_ssize_t length,
        PyObject *mapping, const(char) *errors
      );
    PyObject *PyUnicode_AsCharmapString(PyObject *unicode, PyObject *mapping);
    PyObject *PyUnicode_EncodeCharmap(Py_UNICODE *data, Py_ssize_t length,
        PyObject *mapping, const(char) *errors
      );
    PyObject *PyUnicode_TranslateCharmap(Py_UNICODE *data, Py_ssize_t length,
        PyObject *table, const(char) *errors
      );

    version (Windows) {
      PyObject *PyUnicode_DecodeMBCS(const(char) *string, Py_ssize_t length, const(char) *errors);
      PyObject *PyUnicode_AsMBCSString(PyObject *unicode);
      PyObject *PyUnicode_EncodeMBCS(Py_UNICODE *data, Py_ssize_t length, const(char) *errors);
    }

    int PyUnicode_EncodeDecimal(Py_UNICODE *s, Py_ssize_t length, char *output, const(char) *errors);

    PyObject *PyUnicode_Concat(PyObject *left, PyObject *right);
    PyObject *PyUnicode_Split(PyObject *s, PyObject *sep, Py_ssize_t maxsplit);
    PyObject *PyUnicode_Splitlines(PyObject *s, int keepends);
    PyObject *PyUnicode_RSplit(PyObject *s, PyObject *sep, Py_ssize_t maxsplit);
    PyObject *PyUnicode_Translate(PyObject *str, PyObject *table, const(char) *errors);
    PyObject *PyUnicode_Join(PyObject *separator, PyObject *seq);
    Py_ssize_t PyUnicode_Tailmatch(PyObject *str, PyObject *substr,
        Py_ssize_t start, Py_ssize_t end, int direction
      );
    Py_ssize_t PyUnicode_Find(PyObject *str, PyObject *substr,
        Py_ssize_t start, Py_ssize_t end, int direction
      );
    Py_ssize_t PyUnicode_Count(PyObject *str, PyObject *substr, Py_ssize_t start, Py_ssize_t end);
    PyObject *PyUnicode_Replace(PyObject *str, PyObject *substr,
        PyObject *replstr, Py_ssize_t maxcount
      );
    int PyUnicode_Compare(PyObject *left, PyObject *right);
    PyObject *PyUnicode_Format(PyObject *format, PyObject *args);
    int PyUnicode_Contains(PyObject *container, PyObject *element);
    PyObject *_PyUnicode_XStrip(PyUnicodeObject *self, int striptype,
        PyObject *sepobj
      );

    int _PyUnicode_IsLowercase(Py_UNICODE ch);
    int _PyUnicode_IsUppercase(Py_UNICODE ch);
    int _PyUnicode_IsTitlecase(Py_UNICODE ch);
    int _PyUnicode_IsWhitespace(Py_UNICODE ch);
    int _PyUnicode_IsLinebreak(Py_UNICODE ch);
    Py_UNICODE _PyUnicode_ToLowercase(Py_UNICODE ch);
    Py_UNICODE _PyUnicode_ToUppercase(Py_UNICODE ch);
    Py_UNICODE _PyUnicode_ToTitlecase(Py_UNICODE ch);
    int _PyUnicode_ToDecimalDigit(Py_UNICODE ch);
    int _PyUnicode_ToDigit(Py_UNICODE ch);
    double _PyUnicode_ToNumeric(Py_UNICODE ch);
    int _PyUnicode_IsDecimalDigit(Py_UNICODE ch);
    int _PyUnicode_IsDigit(Py_UNICODE ch);
    int _PyUnicode_IsNumeric(Py_UNICODE ch);
    int _PyUnicode_IsAlpha(Py_UNICODE ch);

  };

mixin(substitute_and_alias(unicode_funs));

  alias _PyUnicode_IsWhitespace Py_UNICODE_ISSPACE;
  alias _PyUnicode_IsLowercase Py_UNICODE_ISLOWER;
  alias _PyUnicode_IsUppercase Py_UNICODE_ISUPPER;
  alias _PyUnicode_IsTitlecase Py_UNICODE_ISTITLE;
  alias _PyUnicode_IsLinebreak Py_UNICODE_ISLINEBREAK;
  alias _PyUnicode_ToLowercase Py_UNICODE_TOLOWER;
  alias _PyUnicode_ToUppercase Py_UNICODE_TOUPPER;
  alias _PyUnicode_ToTitlecase Py_UNICODE_TOTITLE;
  alias _PyUnicode_IsDecimalDigit Py_UNICODE_ISDECIMAL;
  alias _PyUnicode_IsDigit Py_UNICODE_ISDIGIT;
  alias _PyUnicode_IsNumeric Py_UNICODE_ISNUMERIC;
  alias _PyUnicode_ToDecimalDigit Py_UNICODE_TODECIMAL;
  alias _PyUnicode_ToDigit Py_UNICODE_TODIGIT;
  alias _PyUnicode_ToNumeric Py_UNICODE_TONUMERIC;
  alias _PyUnicode_IsAlpha Py_UNICODE_ISALPHA;

  int Py_UNICODE_ISALNUM()(Py_UNICODE ch) {
    return (
           Py_UNICODE_ISALPHA(ch)
        || Py_UNICODE_ISDECIMAL(ch)
        || Py_UNICODE_ISDIGIT(ch)
        || Py_UNICODE_ISNUMERIC(ch)
      );
  }

  void Py_UNICODE_COPY()(void *target, void *source, size_t length) {
    memcpy(target, source, cast(uint)(length * Py_UNICODE.sizeof));
  }

  void Py_UNICODE_FILL()(Py_UNICODE *target, Py_UNICODE value, size_t length) {
    for (size_t i = 0; i < length; i++) {
      target[i] = value;
    }
  }

  int Py_UNICODE_MATCH()(PyUnicodeObject *string, size_t offset,
      PyUnicodeObject *substring
    )
  {
    return (
         (*(string.str + offset) == *(substring.str))
      && !memcmp(string.str + offset, substring.str,
             substring.length * Py_UNICODE.sizeof
          )
      );
  }


///////////////////////////////////////////////////////////////////////////////
// INT INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/intobject.h:

  struct PyIntObject {
    mixin PyObject_HEAD;

    C_long ob_ival;
  }

  // &PyInt_Type is accessible via PyInt_Type_p.

  // D translation of C macro:
  int PyInt_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, PyInt_Type_p);
  }
  // D translation of C macro:
  int PyInt_CheckExact()(PyObject *op) {
    return op.ob_type == PyInt_Type_p;
  }

  PyObject *PyInt_FromString(char *, char **, int);
  PyObject *PyInt_FromUnicode(Py_UNICODE *, Py_ssize_t, int);
  PyObject *PyInt_FromLong(C_long);
  version(Python_2_5_Or_Later){
      PyObject *PyInt_FromSize_t(size_t);
      PyObject *PyInt_FromSsize_t(Py_ssize_t);

      Py_ssize_t PyInt_AsSsize_t(PyObject*);
  }

  C_long PyInt_AsLong(PyObject *);
  C_ulong PyInt_AsUnsignedLongMask(PyObject *);
  C_ulonglong PyInt_AsUnsignedLongLongMask(PyObject *);

  C_long PyInt_GetMax(); /* Accessible at the Python level as sys.maxint */

  C_ulong PyOS_strtoul(char *, char **, int);
  C_long PyOS_strtol(char *, char **, int);
  version(Python_2_6_Or_Later){
      C_long PyOS_strtol(char *, char **, int);

      /* free list api */
      int PyInt_ClearFreeList();

      /* Convert an integer to the given base.  Returns a string.
         If base is 2, 8 or 16, add the proper prefix '0b', '0o' or '0x'.
         If newstyle is zero, then use the pre-2.6 behavior of octal having
         a leading "0" */
      PyObject* _PyInt_Format(PyIntObject* v, int base, int newstyle);

      /* Format the object based on the format_spec, as defined in PEP 3101
         (Advanced String Formatting). */
      PyObject * _PyInt_FormatAdvanced(PyObject *obj,
              char *format_spec,
              Py_ssize_t format_spec_len);
  }


///////////////////////////////////////////////////////////////////////////////
// BOOL INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/boolobject.h:

  alias PyIntObject PyBoolObject;

  // &PyBool_Type is accessible via PyBool_Type_p.

  // D translation of C macro:
  int PyBool_Check()(PyObject *x) {
    return x.ob_type == PyBool_Type_p;
  }

  // Py_False and Py_True are actually macros in the Python/C API, so they're
  // loaded as PyObject pointers in this module static initializer.

  PyObject * PyBool_FromLong(C_long);


///////////////////////////////////////////////////////////////////////////////
// LONG INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/longobject.h:

  // &PyLong_Type is accessible via PyLong_Type_p.

  version(Python_2_6_Or_Later){
      int PyLong_Check()(PyObject* op){
          return PyType_FastSubclass((op).ob_type, Py_TPFLAGS_LONG_SUBCLASS);
      }
  }else{
      // D translation of C macro:
      int PyLong_Check()(PyObject *op) {
          return PyObject_TypeCheck(op, PyLong_Type_p);
      }
  }
  // D translation of C macro:
  int PyLong_CheckExact()(PyObject *op) {
      return op.ob_type == PyLong_Type_p;
  }

  PyObject * PyLong_FromLong(C_long);
  PyObject * PyLong_FromUnsignedLong(C_ulong);

  PyObject * PyLong_FromLongLong(C_longlong);
  PyObject * PyLong_FromUnsignedLongLong(C_ulonglong);

  PyObject * PyLong_FromDouble(double);
  version(Python_2_6_Or_Later){
      PyObject * PyLong_FromSize_t(size_t);
      PyObject * PyLong_FromSsize_t(Py_ssize_t);
  }
  PyObject * PyLong_FromVoidPtr(void *);

  C_long PyLong_AsLong(PyObject *);
  C_ulong PyLong_AsUnsignedLong(PyObject *);
  C_ulong PyLong_AsUnsignedLongMask(PyObject *);
  version(Python_2_6_Or_Later){
      Py_ssize_t PyLong_AsSsize_t(PyObject *);
  }

  C_longlong PyLong_AsLongLong(PyObject *);
  C_ulonglong PyLong_AsUnsignedLongLong(PyObject *);
  C_ulonglong PyLong_AsUnsignedLongLongMask(PyObject *);
  version(Python_2_7_Or_Later) {
      C_long PyLong_AsLongAndOverflow(PyObject*, int*);
      C_longlong PyLong_AsLongLongAndOverflow(PyObject*, int*);
  }

  double PyLong_AsDouble(PyObject *);
  PyObject * PyLong_FromVoidPtr(void *);
  void * PyLong_AsVoidPtr(PyObject *);

  PyObject * PyLong_FromString(char *, char **, int);
  PyObject * PyLong_FromUnicode(Py_UNICODE *, int, int);
  int _PyLong_Sign(PyObject* v);
  size_t _PyLong_NumBits(PyObject* v);
  PyObject* _PyLong_FromByteArray(
	const(ubyte)* bytes, size_t n,
	int little_endian, int is_signed);
  int _PyLong_AsByteArray(PyLongObject* v,
	ubyte* bytes, size_t n,
	int little_endian, int is_signed);

  version(Python_2_6_Or_Later){
      /* _PyLong_Format: Convert the long to a string object with given base,
         appending a base prefix of 0[box] if base is 2, 8 or 16.
         Add a trailing "L" if addL is non-zero.
         If newstyle is zero, then use the pre-2.6 behavior of octal having
         a leading "0", instead of the prefix "0o" */
      PyObject * _PyLong_Format(PyObject *aa, int base, int addL, int newstyle);

      /* Format the object based on the format_spec, as defined in PEP 3101
         (Advanced String Formatting). */
      PyObject * _PyLong_FormatAdvanced(PyObject *obj,
					      char *format_spec,
					      Py_ssize_t format_spec_len);
  }

// Python-header-file: Include/longintrepr.h:

struct PyLongObject {
	mixin PyObject_VAR_HEAD;
	ushort ob_digit[1];
}

PyLongObject* _PyLong_New(int);

/* Return a copy of src. */
PyObject* _PyLong_Copy(PyLongObject* src);

///////////////////////////////////////////////////////////////////////////////
// FLOAT INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/floatobject.h:

  struct PyFloatObject {
    mixin PyObject_HEAD;

    double ob_fval;
  }

  // &PyFloat_Type is accessible via PyFloat_Type_p.

  // D translation of C macro:
  int PyFloat_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, PyFloat_Type_p);
  }
  // D translation of C macro:
  int PyFloat_CheckExact()(PyObject *op) {
    return op.ob_type == PyFloat_Type_p;
  }

  version(Python_2_6_Or_Later){
      double PyFloat_GetMax();
      double PyFloat_GetMin();
      PyObject * PyFloat_GetInfo();
  }

  PyObject * PyFloat_FromString(PyObject *, char** junk);
  PyObject * PyFloat_FromDouble(double);

  double PyFloat_AsDouble(PyObject *);
  void PyFloat_AsReprString(char *, PyFloatObject *v);
  void PyFloat_AsString(char *, PyFloatObject *v);

  version(Python_2_6_Or_Later){
      // _PyFloat_Digits ??
      // _PyFloat_DigitsInit ??
      /* free list api */
      int PyFloat_ClearFreeList();
      // _PyFloat_FormatAdvanced ??
  }


///////////////////////////////////////////////////////////////////////////////
// COMPLEX INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/complexobject.h:

  struct Py_complex {
    double real_; // real is the name of a D type, so must rename
    double imag;
  }

  struct PyComplexObject {
    mixin PyObject_HEAD;

    Py_complex cval;
  }

  Py_complex c_sum(Py_complex, Py_complex);
  Py_complex c_diff(Py_complex, Py_complex);
  Py_complex c_neg(Py_complex);
  Py_complex c_prod(Py_complex, Py_complex);
  Py_complex c_quot(Py_complex, Py_complex);
  Py_complex c_pow(Py_complex, Py_complex);
  version(Python_2_6_Or_Later){
      double c_abs(Py_complex);
  }

  // &PyComplex_Type is accessible via PyComplex_Type_p.

  // D translation of C macro:
  int PyComplex_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, PyComplex_Type_p);
  }
  // D translation of C macro:
  int PyComplex_CheckExact()(PyObject *op) {
    return op.ob_type == PyComplex_Type_p;
  }

  PyObject * PyComplex_FromCComplex(Py_complex);
  PyObject * PyComplex_FromDoubles(double real_, double imag);

  double PyComplex_RealAsDouble(PyObject *op);
  double PyComplex_ImagAsDouble(PyObject *op);
  Py_complex PyComplex_AsCComplex(PyObject *op);


///////////////////////////////////////////////////////////////////////////////
// RANGE INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/rangeobject.h:

  // &PyRange_Type is accessible via PyRange_Type_p.

  // D translation of C macro:
  int PyRange_Check()(PyObject *op) {
    return op.ob_type == PyRange_Type_p;
  }

  version(Python_2_5_Or_Later){
      // Removed in 2.5
  }else{
      PyObject * PyRange_New(C_long, C_long, C_long, int);
  }


///////////////////////////////////////////////////////////////////////////////
// STRING INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/stringobject.h:

  struct PyStringObject {
    mixin PyObject_VAR_HEAD;

    C_long ob_shash;
    int ob_sstate;
    // DSR:XXX:LAYOUT:
    // Will the D layout for a 1-char array be the same as the C layout?  I
    // think the D array will be larger.
    char _ob_sval[1];
    char* ob_sval()() {
        return _ob_sval.ptr;
    }
  }

  // &PyBaseString_Type is accessible via PyBaseString_Type_p.
  // &PyString_Type is accessible via PyString_Type_p.

  // D translation of C macro:
  int PyString_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, PyString_Type_p);
  }
  // D translation of C macro:
  int PyString_CheckExact()(PyObject *op) {
    return op.ob_type == PyString_Type_p;
  }

  PyObject * PyString_FromStringAndSize(const(char) *, Py_ssize_t);
  PyObject * PyString_FromString(const(char) *);
  // PyString_FromFormatV omitted
  PyObject * PyString_FromFormat(const(char)*, ...);
  Py_ssize_t PyString_Size(PyObject *);
  const(char)* PyString_AsString(PyObject *);
  /* Use only if you know it's a string */
  int PyString_CHECK_INTERNED()(PyObject* op) {
    return (cast(PyStringObject*)op).ob_sstate;
  }
  /* Macro, trading safety for speed */
  const(char)* PyString_AS_STRING()(PyObject* op) {
    return (cast(PyStringObject*)op).ob_sval;
  }
  Py_ssize_t PyString_GET_SIZE()(PyObject* op) {
    return (cast(PyStringObject*)op).ob_size;
  }
  PyObject * PyString_Repr(PyObject *, int);
  void PyString_Concat(PyObject **, PyObject *);
  void PyString_ConcatAndDel(PyObject **, PyObject *);
  PyObject * PyString_Format(PyObject *, PyObject *);
  PyObject * PyString_DecodeEscape(const(char) *, Py_ssize_t, const(char) *, Py_ssize_t, const(char) *);

  void PyString_InternInPlace(PyObject **);
  void PyString_InternImmortal(PyObject **);
  PyObject * PyString_InternFromString(const(char) *);

  PyObject * _PyString_Join(PyObject *sep, PyObject *x);


  PyObject* PyString_Decode(const(char) *s, Py_ssize_t size, const(char) *encoding, const(char) *errors);
  PyObject* PyString_Encode(const(char) *s, Py_ssize_t size, const(char) *encoding, const(char) *errors);

  PyObject* PyString_AsEncodedObject(PyObject *str, const(char) *encoding, const(char) *errors);
  PyObject* PyString_AsDecodedObject(PyObject *str, const(char) *encoding, const(char) *errors);

  // Since no one has legacy Python extensions written in D, the deprecated
  // functions PyString_AsDecodedString and PyString_AsEncodedString were
  // omitted.

  int PyString_AsStringAndSize(PyObject *obj, char **s, int *len);

  version(Python_2_6_Or_Later){
      /* Using the current locale, insert the thousands grouping
         into the string pointed to by buffer.  For the argument descriptions,
         see Objects/stringlib/localeutil.h */

      int _PyString_InsertThousandsGrouping(char *buffer,
              Py_ssize_t n_buffer,
              Py_ssize_t n_digits,
              Py_ssize_t buf_size,
              Py_ssize_t *count,
              int append_zero_char);

      /* Format the object based on the format_spec, as defined in PEP 3101
         (Advanced String Formatting). */
      PyObject * _PyBytes_FormatAdvanced(PyObject *obj,
              char *format_spec,
              Py_ssize_t format_spec_len);
  }


///////////////////////////////////////////////////////////////////////////////
// BUFFER INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/bufferobject.h:

  // &PyBuffer_Type is accessible via PyBuffer_Type_p.

  // D translation of C macro:
  int PyBuffer_Check()(PyObject *op) {
    return op.ob_type == PyBuffer_Type_p;
  }

  enum int Py_END_OF_BUFFER = -1;

  PyObject * PyBuffer_FromObject(PyObject *base, Py_ssize_t offset, Py_ssize_t size);
  PyObject * PyBuffer_FromReadWriteObject(PyObject *base, Py_ssize_t offset, Py_ssize_t size);

  PyObject * PyBuffer_FromMemory(void *ptr, Py_ssize_t size);
  PyObject * PyBuffer_FromReadWriteMemory(void *ptr, Py_ssize_t size);

  PyObject * PyBuffer_New(Py_ssize_t size);


///////////////////////////////////////////////////////////////////////////////
// TUPLE INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/tupleobject.h:

  struct PyTupleObject {
    mixin PyObject_VAR_HEAD;

    // DSR:XXX:LAYOUT:
    // Will the D layout for a 1-PyObject* array be the same as the C layout?
    // I think the D array will be larger.
    PyObject *_ob_item[1];
    PyObject** ob_item()() {
      return _ob_item.ptr;
    }
  }

  // &PyTuple_Type is accessible via PyTuple_Type_p.

  // D translation of C macro:
  int PyTuple_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, PyTuple_Type_p);
  }
  // D translation of C macro:
  int PyTuple_CheckExact()(PyObject *op) {
    return op.ob_type == PyTuple_Type_p;
  }

  PyObject * PyTuple_New(Py_ssize_t size);
  Py_ssize_t PyTuple_Size(PyObject *);
  Borrowed!PyObject* PyTuple_GetItem(PyObject*, Py_ssize_t);
  int PyTuple_SetItem(PyObject *, Py_ssize_t, PyObject *);
  PyObject * PyTuple_GetSlice(PyObject *, Py_ssize_t, Py_ssize_t);
  int _PyTuple_Resize(PyObject **, Py_ssize_t);
  PyObject * PyTuple_Pack(Py_ssize_t, ...);

  // D translations of C macros:
  // XXX: These do not work.
  Borrowed!PyObject* PyTuple_GET_ITEM()(PyObject* op, Py_ssize_t i) {
    return (cast(PyTupleObject *) op).ob_item[i];
  }
  size_t PyTuple_GET_SIZE()(PyObject *op) {
    return (cast(PyTupleObject *) op).ob_size;
  }
  PyObject *PyTuple_SET_ITEM()(PyObject *op, Py_ssize_t i, PyObject *v) {
    PyTupleObject *opAsTuple = cast(PyTupleObject *) op;
    opAsTuple.ob_item[i] = v;
    return v;
  }

  version(Python_2_6_Or_Later){
      int PyTuple_ClearFreeList();
  }

///////////////////////////////////////////////////////////////////////////////
// LIST INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/listobject.h:

  struct PyListObject {
    mixin PyObject_VAR_HEAD;

    PyObject **ob_item;
    Py_ssize_t allocated;
  }

  // &PyList_Type is accessible via PyList_Type_p.

  // D translation of C macro:
  int PyList_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, PyList_Type_p);
  }
  // D translation of C macro:
  int PyList_CheckExact()(PyObject *op) {
    return op.ob_type == PyList_Type_p;
  }

  PyObject * PyList_New(Py_ssize_t size);
  Py_ssize_t PyList_Size(PyObject *);

  Borrowed!PyObject* PyList_GetItem(PyObject*, Py_ssize_t);
  int PyList_SetItem(PyObject*, Py_ssize_t, PyObject*);
  int PyList_Insert(PyObject*, Py_ssize_t, PyObject*);
  int PyList_Append(PyObject*, PyObject*);
  PyObject* PyList_GetSlice(PyObject*, Py_ssize_t, Py_ssize_t);
  int PyList_SetSlice(PyObject*, Py_ssize_t, Py_ssize_t, PyObject*);
  int PyList_Sort(PyObject*);
  int PyList_Reverse(PyObject*);
  PyObject* PyList_AsTuple(PyObject*);

  // D translations of C macros:
  Borrowed!PyObject* PyList_GET_ITEM()(PyObject* op, Py_ssize_t i) {
    return (cast(PyListObject*) op).ob_item[i];
  }
  void PyList_SET_ITEM()(PyObject *op, Py_ssize_t i, PyObject *v) {
    (cast(PyListObject*)op).ob_item[i] = v;
  }
  Py_ssize_t PyList_GET_SIZE()(PyObject *op) {
    return (cast(PyListObject *) op).ob_size;
  }


///////////////////////////////////////////////////////////////////////////////
// DICTIONARY OBJECT TYPE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/dictobject.h:

  enum int PyDict_MINSIZE = 8;

  struct PyDictEntry {
      version(Python_2_5_Or_Later){
          Py_ssize_t me_hash;
      }else{
          C_long me_hash;
      }
    PyObject *me_key;
    PyObject *me_value;
  }

  struct _dictobject {
    mixin PyObject_HEAD;

    Py_ssize_t ma_fill;
    Py_ssize_t ma_used;
    Py_ssize_t ma_mask;
    PyDictEntry *ma_table;
    PyDictEntry* function(PyDictObject *mp, PyObject *key, C_long hash) ma_lookup;
    PyDictEntry ma_smalltable[PyDict_MINSIZE];
  }
  alias _dictobject PyDictObject;

  // &PyDict_Type is accessible via PyDict_Type_p.

  // D translation of C macro:
  int PyDict_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, PyDict_Type_p);
  }
  // D translation of C macro:
  int PyDict_CheckExact()(PyObject *op) {
    return op.ob_type == PyDict_Type_p;
  }

  PyObject* PyDict_New();
  Borrowed!PyObject* PyDict_GetItem(PyObject* mp, PyObject* key);
  int PyDict_SetItem(PyObject* mp, PyObject* key, PyObject* item);
  int PyDict_DelItem(PyObject *mp, PyObject *key);
  void PyDict_Clear(PyObject *mp);
  int PyDict_Next(PyObject *mp, Py_ssize_t *pos, Borrowed!PyObject** key, Borrowed!PyObject** value);
  PyObject * PyDict_Keys(PyObject *mp);
  PyObject * PyDict_Values(PyObject *mp);
  PyObject * PyDict_Items(PyObject *mp);
  Py_ssize_t PyDict_Size(PyObject *mp);
  PyObject * PyDict_Copy(PyObject *mp);
  int PyDict_Contains(PyObject *mp, PyObject *key);

  int PyDict_Update(PyObject *mp, PyObject *other);
  int PyDict_Merge(PyObject *mp, PyObject *other, int override_);
  int PyDict_MergeFromSeq2(PyObject *d, PyObject *seq2, int override_);

  Borrowed!PyObject* PyDict_GetItemString(PyObject* dp, const(char)* key);
  int PyDict_SetItemString(PyObject* dp, const(char)* key, PyObject* item);
  int PyDict_DelItemString(PyObject* dp, const(char)* key);


///////////////////////////////////////////////////////////////////////////////
// PYTHON EXTENSION FUNCTION INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/methodobject.h:

  // &PyCFunction_Type is accessible via PyCFunction_Type_p.

  // D translation of C macro:
  int PyCFunction_Check()(PyObject *op) {
    return op.ob_type == PyCFunction_Type_p;
  }

  alias PyObject* function(PyObject *, PyObject *) PyCFunction;
  alias PyObject* function(PyObject *, PyObject *,PyObject *) PyCFunctionWithKeywords;
  alias PyObject* function(PyObject *) PyNoArgsFunction;

  PyCFunction PyCFunction_GetFunction(PyObject *);
  PyObject * PyCFunction_GetSelf(PyObject *);
  int PyCFunction_GetFlags(PyObject *);

  PyObject * PyCFunction_Call(PyObject *, PyObject *, PyObject *);

      version(Python_2_5_Or_Later){
          alias const(char)	Char1;
      }else{
          alias char	Char1;
      }
  struct PyMethodDef {
      Char1	*ml_name;
      PyCFunction  ml_meth;
      int		 ml_flags;
      Char1	*ml_doc;
  }

  PyObject * Py_FindMethod(PyMethodDef[], PyObject *, Char1 *);
  PyObject * PyCFunction_NewEx(PyMethodDef *, PyObject *,PyObject *);
  PyObject * PyCFunction_New()(PyMethodDef* ml, PyObject* self) {
    return PyCFunction_NewEx(ml, self, null);
  }

  enum int METH_OLDARGS = 0x0000;
  enum int METH_VARARGS = 0x0001;
  enum int METH_KEYWORDS= 0x0002;
  enum int METH_NOARGS  = 0x0004;
  enum int METH_O       = 0x0008;
  enum int METH_CLASS   = 0x0010;
  enum int METH_STATIC  = 0x0020;
  enum int METH_COEXIST = 0x0040;

  struct PyMethodChain {
    PyMethodDef *methods;
    PyMethodChain *link;
  }

  PyObject * Py_FindMethodInChain(PyMethodChain *, PyObject *, Char1 *);

  struct PyCFunctionObject {
    mixin PyObject_HEAD;

    PyMethodDef *m_ml;
    PyObject    *m_self;
    PyObject    *m_module;
  }

  version(Python_2_6_Or_Later){
      int PyCFunction_ClearFreeList();
  }


///////////////////////////////////////////////////////////////////////////////
// MODULE INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/moduleobject.h:

  // &PyModule_Type is accessible via PyModule_Type_p.

  // D translation of C macro:
  int PyModule_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, PyModule_Type_p);
  }
  // D translation of C macro:
  int PyModule_CheckExact()(PyObject *op) {
    return op.ob_type == PyModule_Type_p;
  }

  PyObject* PyModule_New(Char1*);
  Borrowed!PyObject* PyModule_GetDict(PyObject*);
  char* PyModule_GetName(PyObject*);
  char* PyModule_GetFilename(PyObject*);
  void _PyModule_Clear(PyObject *);

  // Python-header-file: Include/modsupport.h:

      version(Python_2_5_Or_Later){
          enum PYTHON_API_VERSION = 1013;
          enum PYTHON_API_STRING = "1013";
      }else version(Python_2_4_Or_Later){
          enum PYTHON_API_VERSION = 1012;
          enum PYTHON_API_STRING = "1012";
      }

  int PyArg_Parse(PyObject *, Char1 *, ...);
  int PyArg_ParseTuple(PyObject *, Char1 *, ...);
  int PyArg_ParseTupleAndKeywords(PyObject *, PyObject *,
                            Char1 *, char **, ...);
  int PyArg_UnpackTuple(PyObject *, Char1 *, Py_ssize_t, Py_ssize_t, ...);
  PyObject * Py_BuildValue(Char1 *, ...);

  int PyModule_AddObject(PyObject *, Char1 *, PyObject *);
  int PyModule_AddIntConstant(PyObject *, Char1 *, C_long);
  int PyModule_AddStringConstant(PyObject *, Char1 *, Char1 *);

  version(Python_2_5_Or_Later){
      version(X86_64){
          enum Py_InitModuleSym = "Py_InitModule4_64";
      }else{
          enum Py_InitModuleSym = "Py_InitModule4";
      }
  }else{
      enum Py_InitModuleSym = "Py_InitModule4";
  }
  mixin("Borrowed!PyObject* "~Py_InitModuleSym~"(Char1 *name, PyMethodDef *methods, Char1 *doc,
                  PyObject *self, int apiver);

  Borrowed!PyObject* Py_InitModule()(string name, PyMethodDef *methods)
  {
    return "~Py_InitModuleSym~"(cast(Char1*) name.ptr, methods, cast(Char1 *)(null),
      cast(PyObject *)(null), PYTHON_API_VERSION);
  }

  Borrowed!PyObject* Py_InitModule3()(string name, PyMethodDef *methods, string doc) {
    return "~Py_InitModuleSym~"(cast(Char1*)name.ptr, methods, cast(Char1*) doc, cast(PyObject *)null,
      PYTHON_API_VERSION);
  }");


///////////////////////////////////////////////////////////////////////////////
// PYTHON FUNCTION INTERFACE (to functions created by the 'def' statement)
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/funcobject.h:

  struct PyFunctionObject {
    mixin PyObject_HEAD;

    PyObject *func_code;
    PyObject *func_globals;
    PyObject *func_defaults;
    PyObject *func_closure;
    PyObject *func_doc;
    PyObject *func_name;
    PyObject *func_dict;
    PyObject *func_weakreflist;
    PyObject *func_module;
  }

  // &PyFunction_Type is accessible via PyFunction_Type_p.

  // D translation of C macro:
  int PyFunction_Check()(PyObject *op) {
    return op.ob_type == PyFunction_Type_p;
  }

  PyObject * PyFunction_New(PyObject *, PyObject *);
  Borrowed!PyObject* PyFunction_GetCode(PyObject*);
  Borrowed!PyObject* PyFunction_GetGlobals(PyObject*);
  Borrowed!PyObject* PyFunction_GetModule(PyObject*);
  Borrowed!PyObject* PyFunction_GetDefaults(PyObject*);
  int PyFunction_SetDefaults(PyObject *, PyObject *);
  Borrowed!PyObject* PyFunction_GetClosure(PyObject *);
  int PyFunction_SetClosure(PyObject *, PyObject *);

  PyObject* PyFunction_GET_CODE()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_code;
  }
  PyObject* PyFunction_GET_GLOBALS()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_globals;
  }
  PyObject* PyFunction_GET_MODULE()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_module;
  }
  PyObject* PyFunction_GET_DEFAULTS()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_defaults;
  }
  PyObject* PyFunction_GET_CLOSURE()(PyObject* func) {
    return (cast(PyFunctionObject*)func).func_closure;
  }

  // &PyClassMethod_Type is accessible via PyClassMethod_Type_p.
  // &PyStaticMethod_Type is accessible via PyStaticMethod_Type_p.

  PyObject * PyClassMethod_New(PyObject *);
  PyObject * PyStaticMethod_New(PyObject *);


///////////////////////////////////////////////////////////////////////////////
// PYTHON CLASS INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/classobject.h:

  struct PyClassObject {
    mixin PyObject_HEAD;

    PyObject	*cl_bases;	/* A tuple of class objects */
    PyObject	*cl_dict;	/* A dictionary */
    PyObject	*cl_name;	/* A string */
    /* The following three are functions or null */
    PyObject	*cl_getattr;
    PyObject	*cl_setattr;
    PyObject	*cl_delattr;
  }

  struct PyInstanceObject {
    mixin PyObject_HEAD;

    PyClassObject *in_class;
    PyObject	  *in_dict;
    PyObject	  *in_weakreflist;
  }

  struct PyMethodObject {
    mixin PyObject_HEAD;

    PyObject *im_func;
    PyObject *im_self;
    PyObject *im_class;
    PyObject *im_weakreflist;
  }

  // &PyClass_Type is accessible via PyClass_Type_p.
  // D translation of C macro:
  int PyClass_Check()(PyObject *op) {
    return op.ob_type == PyClass_Type_p;
  }

  // &PyInstance_Type is accessible via PyInstance_Type_p.
  // D translation of C macro:
  int PyInstance_Check()(PyObject *op) {
    return op.ob_type == PyInstance_Type_p;
  }

  // &PyMethod_Type is accessible via PyMethod_Type_p.
  // D translation of C macro:
  int PyMethod_Check()(PyObject *op) {
    return op.ob_type == PyMethod_Type_p;
  }

  PyObject * PyClass_New(PyObject *, PyObject *, PyObject *);
  PyObject * PyInstance_New(PyObject *, PyObject *,
                        PyObject *);
  PyObject * PyInstance_NewRaw(PyObject *, PyObject *);
  PyObject * PyMethod_New(PyObject *, PyObject *, PyObject *);

  Borrowed!PyObject* PyMethod_Function(PyObject *);
  Borrowed!PyObject* PyMethod_Self(PyObject *);
  Borrowed!PyObject* PyMethod_Class(PyObject*);

  PyObject * _PyInstance_Lookup(PyObject *pinst, PyObject *name);

  Borrowed!PyObject* PyMethod_GET_FUNCTION()(PyObject* meth) {
    return (cast(PyMethodObject*)meth).im_func;
  }
  Borrowed!PyObject* PyMethod_GET_SELF()(PyObject* meth) {
    return (cast(PyMethodObject*)meth).im_self;
  }
  Borrowed!PyObject* PyMethod_GET_CLASS()(PyObject* meth) {
    return borrowed((cast(PyMethodObject*)meth).im_class);
  }

  int PyClass_IsSubclass(PyObject *, PyObject *);

  version(Python_2_6_Or_Later){
      int PyMethod_ClearFreeList();
  }


///////////////////////////////////////////////////////////////////////////////
// FILE INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/fileobject.h:

  struct PyFileObject {
    mixin PyObject_HEAD;

    FILE *f_fp;
    PyObject *f_name;
    PyObject *f_mode;
    int function(FILE *) f_close;
    int f_softspace;
    int f_binary;
    char* f_buf;
    char* f_bufend;
    char* f_bufptr;
    char *f_setbuf;
    int f_univ_newline;
    int f_newlinetypes;
    int f_skipnextlf;
    PyObject *f_encoding;
    version(Python_2_6_Or_Later){
        PyObject *f_errors;
    }
    PyObject *weakreflist;
    version(Python_2_6_Or_Later){
        int unlocked_count;         /* Num. currently running sections of code
                                       using f_fp with the GIL released. */
        int readable;
        int writable;
    }
  }

  // &PyFile_Type is accessible via PyFile_Type_p.
  // D translation of C macro:
  int PyFile_Check()(PyObject *op) {
    return PyObject_TypeCheck(op, PyFile_Type_p);
  }
  // D translation of C macro:
  int PyFile_CheckExact()(PyObject *op) {
    return op.ob_type == PyFile_Type_p;
  }

  PyObject * PyFile_FromString(char *, char *);
  void PyFile_SetBufSize(PyObject *, int);
  int PyFile_SetEncoding(PyObject *, const(char) *);
  version(Python_2_6_Or_Later){
      int PyFile_SetEncodingAndErrors(PyObject *, const(char)*, const(char)*errors);
  }
  PyObject * PyFile_FromFile(FILE *, char *, char *,
                         int function(FILE *));
  FILE * PyFile_AsFile(PyObject *);
  version(Python_2_6_Or_Later){
      void PyFile_IncUseCount(PyFileObject *);
      void PyFile_DecUseCount(PyFileObject *);
  }
  Borrowed!PyObject* PyFile_Name(PyObject*);
  PyObject * PyFile_GetLine(PyObject *, int);
  int PyFile_WriteObject(PyObject *, PyObject *, int);
  int PyFile_SoftSpace(PyObject *, int);
  int PyFile_WriteString(const(char)*, PyObject *);
  int PyObject_AsFileDescriptor(PyObject *);

  // We deal with char *Py_FileSystemDefaultEncoding in the global variables
  // section toward the bottom of this file.

  enum PY_STDIOTEXTMODE = "b";

  char *Py_UniversalNewlineFgets(char *, int, FILE*, PyObject *);
  size_t Py_UniversalNewlineFread(char *, size_t, FILE *, PyObject *);


///////////////////////////////////////////////////////////////////////////////
// COBJECT INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/cobject.h:

  // PyCObject_Type is a Python type for transporting an arbitrary C pointer
  // from the C level to Python and back (in essence, an opaque handle).

  // &PyCObject_Type is accessible via PyCObject_Type_p.
  // D translation of C macro:
  int PyCObject_Check()(PyObject *op) {
    return op.ob_type == PyCObject_Type_p;
  }

  PyObject * PyCObject_FromVoidPtr(void *cobj, void function(void*) destruct);
  PyObject * PyCObject_FromVoidPtrAndDesc(void *cobj, void *desc,
    void function(void*,void*) destruct);
  void * PyCObject_AsVoidPtr(PyObject *);
  void * PyCObject_GetDesc(PyObject *);
  void * PyCObject_Import(char *module_name, char *cobject_name);
  int PyCObject_SetVoidPtr(PyObject *self, void *cobj);

  version(Python_2_6_Or_Later){
      struct PyCObject {
          mixin PyObject_HEAD;
          void *cobject;
          void *desc;
          void function(void *) destructor;
      };
  }


///////////////////////////////////////////////////////////////////////////////////////////////
// TRACEBACK INTERFACE
///////////////////////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/traceback.h:

  struct PyTracebackObject {
    mixin PyObject_HEAD;

    PyTracebackObject *tb_next;
    PyFrameObject *tb_frame;
    int tb_lasti;
    int tb_lineno;
  }

  int PyTraceBack_Here(PyFrameObject *);
  int PyTraceBack_Print(PyObject *, PyObject *);
  version(Python_2_6_Or_Later){
      int _Py_DisplaySourceLine(PyObject *, const(char)*, int, int);
  }

  // &PyTraceBack_Type is accessible via PyTraceBack_Type_p.
  // D translation of C macro:
  int PyTraceBack_Check()(PyObject *v) {
    return v.ob_type == PyTraceBack_Type_p;
  }


///////////////////////////////////////////////////////////////////////////////
// SLICE INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/sliceobject.h:

  // We deal with Py_Ellipsis in the global variables section toward the bottom
  // of this file.

  struct PySliceObject {
    mixin PyObject_HEAD;

    PyObject *start;
    PyObject *stop;
    PyObject *step;
  }

  // &PySlice_Type is accessible via PySlice_Type_p.
  // D translation of C macro:
  int PySlice_Check()(PyObject *op) {
    return op.ob_type == PySlice_Type_p;
  }

  PyObject * PySlice_New(PyObject *start, PyObject *stop, PyObject *step);
  int PySlice_GetIndices(PySliceObject *r, Py_ssize_t length,
                Py_ssize_t *start, Py_ssize_t *stop, Py_ssize_t *step);
  int PySlice_GetIndicesEx(PySliceObject *r, Py_ssize_t length,
                Py_ssize_t *start, Py_ssize_t *stop,
                Py_ssize_t *step, Py_ssize_t *slicelength);


///////////////////////////////////////////////////////////////////////////////
// CELL INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/cellobject.h:

  struct PyCellObject {
    mixin PyObject_HEAD;

    PyObject *ob_ref;
  }

  // &PyCell_Type is accessible via PyCell_Type_p.
  // D translation of C macro:
  int PyCell_Check()(PyObject *op) {
    return op.ob_type == PyCell_Type_p;
  }

  PyObject * PyCell_New(PyObject *);
  PyObject * PyCell_Get(PyObject *);
  int PyCell_Set(PyObject *, PyObject *);


///////////////////////////////////////////////////////////////////////////////
// ITERATOR INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/iterobject.h:

  // &PySeqIter_Type is accessible via PySeqIter_Type_p.
  // D translation of C macro:
  int PySeqIter_Check()(PyObject *op) {
    return op.ob_type == PySeqIter_Type_p;
  }

  PyObject * PySeqIter_New(PyObject *);

  // &PyCallIter_Type is accessible via PyCallIter_Type_p.
  // D translation of C macro:
  int PyCallIter_Check()(PyObject *op) {
    return op.ob_type == PyCallIter_Type_p;
  }

  PyObject * PyCallIter_New(PyObject *, PyObject *);


///////////////////////////////////////////////////////////////////////////////
// DESCRIPTOR INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/descrobject.h:

  alias PyObject* function(PyObject *, void *) getter;
  alias int function(PyObject *, PyObject *, void *) setter;

  struct PyGetSetDef {
    char *name;
    getter get;
    setter set;
    char *doc;
    void *closure;
  }

  alias PyObject* function(PyObject *, PyObject *, void *) wrapperfunc;
  alias PyObject* function(PyObject *, PyObject *, void *, PyObject *) wrapperfunc_kwds;

  struct wrapperbase {
    char *name;
    int offset;
    void *function_;
    wrapperfunc wrapper;
    char *doc;
    int flags;
    PyObject *name_strobj;
  }

  enum PyWrapperFlag_KEYWORDS = 1;

  template PyDescr_COMMON() {
    mixin PyObject_HEAD;
    PyTypeObject *d_type;
    PyObject *d_name;
  }

  struct PyDescrObject {
    mixin PyDescr_COMMON;
  }

  struct PyMethodDescrObject {
    mixin PyDescr_COMMON;
    PyMethodDef *d_method;
  }

  struct PyMemberDescrObject {
    mixin PyDescr_COMMON;
    PyMemberDef *d_member;
  }

  struct PyGetSetDescrObject {
    mixin PyDescr_COMMON;
    PyGetSetDef *d_getset;
  }

  struct PyWrapperDescrObject {
    mixin PyDescr_COMMON;
    wrapperbase *d_base;
    void *d_wrapped;
  }

  // PyWrapperDescr_Type is currently not accessible from D.
  version(Python_2_6_Or_Later){
    // nor PyDictProxy_Type;
    // norPyGetSetDescr_Type;
    // nor PyMemberDescr_Type;
  }

  PyObject * PyDescr_NewMethod(PyTypeObject *, PyMethodDef *);
  PyObject * PyDescr_NewClassMethod(PyTypeObject *, PyMethodDef *);
  PyObject * PyDescr_NewMember(PyTypeObject *, PyMemberDef *);
  PyObject * PyDescr_NewGetSet(PyTypeObject *, PyGetSetDef *);
  PyObject * PyDescr_NewWrapper(PyTypeObject *, wrapperbase *, void *);
  PyObject * PyDictProxy_New(PyObject *);
  PyObject * PyWrapper_New(PyObject *, PyObject *);

  // &PyProperty_Type is accessible via PyProperty_Type_p.


///////////////////////////////////////////////////////////////////////////////
// WEAK REFERENCE INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/weakrefobject.h:

  struct PyWeakReference {
    mixin PyObject_HEAD;

    PyObject *wr_object;
    PyObject *wr_callback;
    C_long hash;
    PyWeakReference *wr_prev;
    PyWeakReference *wr_next;
  }

  // &_PyWeakref_RefType is accessible via _PyWeakref_RefType_p.
  // &_PyWeakref_ProxyType is accessible via _PyWeakref_ProxyType_p.
  // &_PyWeakref_CallableProxyType is accessible via _PyWeakref_CallableProxyType_p.

  // D translations of C macros:
  int PyWeakref_CheckRef()(PyObject *op) {
    return PyObject_TypeCheck(op, _PyWeakref_RefType_p);
  }
  int PyWeakref_CheckRefExact()(PyObject *op) {
    return op.ob_type == _PyWeakref_RefType_p;
  }
  int PyWeakref_CheckProxy()(PyObject *op) {
    return op.ob_type == _PyWeakref_ProxyType_p
        || op.ob_type == _PyWeakref_CallableProxyType_p;
  }
  int PyWeakref_Check()(PyObject *op) {
    return PyWeakref_CheckRef(op) || PyWeakref_CheckProxy(op);
  }

  PyObject* PyWeakref_NewRef(PyObject* ob, PyObject* callback);
  PyObject* PyWeakref_NewProxy(PyObject* ob, PyObject* callback);
  Borrowed!PyObject* PyWeakref_GetObject(PyObject* _ref);

  version(Python_2_5_Or_Later){
      Py_ssize_t _PyWeakref_GetWeakrefCount(PyWeakReference* head);
  }else{
      C_long _PyWeakref_GetWeakrefCount(PyWeakReference *head);
  }
  void _PyWeakref_ClearRef(PyWeakReference *self);

  Borrowed!PyObject* PyWeakref_GET_OBJECT()(PyObject* _ref) {
    return (cast(PyWeakReference *) _ref).wr_object;
  }


///////////////////////////////////////////////////////////////////////////////
// CODEC REGISTRY AND SUPPORT INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/codecs.h:

  int PyCodec_Register(PyObject *search_function);
  PyObject * _PyCodec_Lookup(const(char)*encoding);
  PyObject * PyCodec_Encode(PyObject *object, const(char)*encoding, const(char)*errors);
  PyObject * PyCodec_Decode(PyObject *object, const(char)*encoding, const(char)*errors);
  PyObject * PyCodec_Encoder(const(char)*encoding);
  PyObject * PyCodec_Decoder(const(char) *encoding);
  PyObject * PyCodec_StreamReader(const(char) *encoding, PyObject *stream, const(char) *errors);
  PyObject * PyCodec_StreamWriter(const(char) *encoding, PyObject *stream, const(char) *errors);

  /////////////////////////////////////////////////////////////////////////////
  // UNICODE ENCODING INTERFACE
  /////////////////////////////////////////////////////////////////////////////

  int PyCodec_RegisterError(const(char) *name, PyObject *error);
  PyObject * PyCodec_LookupError(const(char) *name);
  PyObject * PyCodec_StrictErrors(PyObject *exc);
  PyObject * PyCodec_IgnoreErrors(PyObject *exc);
  PyObject * PyCodec_ReplaceErrors(PyObject *exc);
  PyObject * PyCodec_XMLCharRefReplaceErrors(PyObject *exc);
  PyObject * PyCodec_BackslashReplaceErrors(PyObject *exc);


///////////////////////////////////////////////////////////////////////////////
// ERROR HANDLING INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/pyerrors.h:

  version(Python_2_5_Or_Later){
  /* Error objects */

  struct PyBaseExceptionObject {
      mixin PyObject_HEAD;
      PyObject *dict;
      PyObject *args;
      PyObject *message;
  }

  struct PySyntaxErrorObject {
      mixin PyObject_HEAD;
      PyObject *dict;
      PyObject *args;
      PyObject *message;
      PyObject *msg;
      PyObject *filename;
      PyObject *lineno;
      PyObject *offset;
      PyObject *text;
      PyObject *print_file_and_line;
  }

  struct PyUnicodeErrorObject {
      mixin PyObject_HEAD;
      PyObject *dict;
      PyObject *args;
      PyObject *message;
      PyObject *encoding;
      PyObject *object;
      version(Python_2_6_Or_Later){
          Py_ssize_t start;
          Py_ssize_t end;
      }else{
          PyObject *start;
          PyObject *end;
      }
      PyObject *reason;
  }

  struct PySystemExitObject {
      mixin PyObject_HEAD;
      PyObject *dict;
      PyObject *args;
      PyObject *message;
      PyObject *code;
  }

  struct PyEnvironmentErrorObject {
      mixin PyObject_HEAD;
      PyObject *dict;
      PyObject *args;
      PyObject *message;
      PyObject *myerrno;
      PyObject *strerror;
      PyObject *filename;
  }

  version(Windows) {
    struct PyWindowsErrorObject {
        mixin PyObject_HEAD;
        PyObject *dict;
        PyObject *args;
        PyObject *message;
        PyObject *myerrno;
        PyObject *strerror;
        PyObject *filename;
        PyObject *winerror;
    }
  }
  }

  void PyErr_SetNone(PyObject *);
  void PyErr_SetObject(PyObject *, PyObject *);
  void PyErr_SetString(PyObject *, const(char) *);
  PyObject * PyErr_Occurred();
  void PyErr_Clear();
  void PyErr_Fetch(PyObject **, PyObject **, PyObject **);
  void PyErr_Restore(PyObject *, PyObject *, PyObject *);

  int PyErr_GivenExceptionMatches(PyObject *, PyObject *);
  int PyErr_ExceptionMatches(PyObject *);
  void PyErr_NormalizeException(PyObject **, PyObject **, PyObject **);

  // All predefined Python exception types are dealt with in the global
  // variables section toward the end of this file.

  int PyErr_BadArgument();
  PyObject * PyErr_NoMemory();
  PyObject * PyErr_SetFromErrno(PyObject *);
  PyObject * PyErr_SetFromErrnoWithFilenameObject(PyObject *, PyObject *);
  PyObject * PyErr_SetFromErrnoWithFilename(PyObject *, char *);
  PyObject * PyErr_SetFromErrnoWithUnicodeFilename(PyObject *, Py_UNICODE *);

  PyObject * PyErr_Format(PyObject *, const(char) *, ...);

  version (Windows) {
    PyObject * PyErr_SetFromWindowsErrWithFilenameObject(int,  const(char) *);
    PyObject * PyErr_SetFromWindowsErrWithFilename(int, const(char) *);
    PyObject * PyErr_SetFromWindowsErrWithUnicodeFilename(int, Py_UNICODE *);
    PyObject * PyErr_SetFromWindowsErr(int);
    PyObject * PyErr_SetExcFromWindowsErrWithFilenameObject(PyObject *, int, PyObject *);
    PyObject * PyErr_SetExcFromWindowsErrWithFilename(PyObject *, int,  const(char) *);
    PyObject * PyErr_SetExcFromWindowsErrWithUnicodeFilename(PyObject *, int, Py_UNICODE *);
    PyObject * PyErr_SetExcFromWindowsErr(PyObject *, int);
  }

  // PyErr_BadInternalCall and friends purposely omitted.

  PyObject * PyErr_NewException(char *name, PyObject *base, PyObject *dict);
  void PyErr_WriteUnraisable(PyObject *);

  version(Python_2_5_Or_Later){
      int PyErr_WarnEx(PyObject*, char*, Py_ssize_t);
  }else{
      int PyErr_Warn(PyObject *, char *);
  }
  int PyErr_WarnExplicit(PyObject *, const(char) *, const(char) *, int, const(char) *, PyObject *);

  int PyErr_CheckSignals();
  void PyErr_SetInterrupt();

  void PyErr_SyntaxLocation(const(char) *, int);
  PyObject * PyErr_ProgramText(const(char) *, int);

  /////////////////////////////////////////////////////////////////////////////
  // UNICODE ENCODING ERROR HANDLING INTERFACE
  /////////////////////////////////////////////////////////////////////////////
  PyObject *PyUnicodeDecodeError_Create(const(char) *, const(char) *, Py_ssize_t, Py_ssize_t, Py_ssize_t, const(char) *);

  PyObject *PyUnicodeEncodeError_Create(const(char) *, Py_UNICODE *, Py_ssize_t, Py_ssize_t, Py_ssize_t, const(char) *);

  PyObject *PyUnicodeTranslateError_Create(Py_UNICODE *, Py_ssize_t, Py_ssize_t, Py_ssize_t, const(char) *);

  PyObject *PyUnicodeEncodeError_GetEncoding(PyObject *);
  PyObject *PyUnicodeDecodeError_GetEncoding(PyObject *);

  PyObject *PyUnicodeEncodeError_GetObject(PyObject *);
  PyObject *PyUnicodeDecodeError_GetObject(PyObject *);
  PyObject *PyUnicodeTranslateError_GetObject(PyObject *);

  int PyUnicodeEncodeError_GetStart(PyObject *, Py_ssize_t *);
  int PyUnicodeDecodeError_GetStart(PyObject *, Py_ssize_t *);
  int PyUnicodeTranslateError_GetStart(PyObject *, Py_ssize_t *);

  int PyUnicodeEncodeError_SetStart(PyObject *, Py_ssize_t);
  int PyUnicodeDecodeError_SetStart(PyObject *, Py_ssize_t);
  int PyUnicodeTranslateError_SetStart(PyObject *, Py_ssize_t);

  int PyUnicodeEncodeError_GetEnd(PyObject *, Py_ssize_t *);
  int PyUnicodeDecodeError_GetEnd(PyObject *, Py_ssize_t *);
  int PyUnicodeTranslateError_GetEnd(PyObject *, Py_ssize_t *);

  int PyUnicodeEncodeError_SetEnd(PyObject *, Py_ssize_t);
  int PyUnicodeDecodeError_SetEnd(PyObject *, Py_ssize_t);
  int PyUnicodeTranslateError_SetEnd(PyObject *, Py_ssize_t);

  PyObject *PyUnicodeEncodeError_GetReason(PyObject *);
  PyObject *PyUnicodeDecodeError_GetReason(PyObject *);
  PyObject *PyUnicodeTranslateError_GetReason(PyObject *);

  int PyUnicodeEncodeError_SetReason(PyObject *, const(char) *);
  int PyUnicodeDecodeError_SetReason(PyObject *, const(char) *);
  int PyUnicodeTranslateError_SetReason(PyObject *, const(char) *);

  int PyOS_snprintf(char *str, size_t size, const(char) *format, ...);
  int PyOS_vsnprintf(char *str, size_t size, const(char) *format, va_list va);


///////////////////////////////////////////////////////////////////////////////
// BYTECODE INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/code.h:

  struct PyCodeObject { /* Bytecode object */
    mixin PyObject_HEAD;

    int co_argcount;
    int co_nlocals;
    int co_stacksize;
    int co_flags;
    PyObject *co_code;
    PyObject *co_consts;
    PyObject *co_names;
    PyObject *co_varnames;
    PyObject *co_freevars;
    PyObject *co_cellvars;

    PyObject *co_filename;
    PyObject *co_name;
    int co_firstlineno;
    PyObject *co_lnotab;
    version(Python_2_5_Or_Later){
        void *co_zombieframe;
    }

  }

  /* Masks for co_flags above */
  enum int CO_OPTIMIZED   = 0x0001;
  enum int CO_NEWLOCALS   = 0x0002;
  enum int CO_VARARGS     = 0x0004;
  enum int CO_VARKEYWORDS = 0x0008;
  enum int CO_NESTED      = 0x0010;
  enum int CO_GENERATOR   = 0x0020;
  enum int CO_NOFREE      = 0x0040;

  version(Python_2_5_Or_Later){
      // Removed in 2.5
  }else{
      enum int CO_GENERATOR_ALLOWED      = 0x1000;
  }
  enum int CO_FUTURE_DIVISION        = 0x2000;
  version(Python_2_5_Or_Later){
      enum int CO_FUTURE_ABSOLUTE_IMPORT = 0x4000;
      enum int CO_FUTURE_WITH_STATEMENT  = 0x8000;
      enum int CO_FUTURE_PRINT_FUNCTION  = 0x10000;
      enum int CO_FUTURE_UNICODE_LITERALS  = 0x20000;
  }

  enum int CO_MAXBLOCKS = 20;

  // &PyCode_Type is accessible via PyCode_Type_p.
  // D translations of C macros:
  int PyCode_Check()(PyObject *op) {
    return op.ob_type == PyCode_Type_p;
  }
  size_t PyCode_GetNumFree()(PyObject *op) {
    return PyObject_Length((cast(PyCodeObject *) op).co_freevars);
  }

  PyCodeObject *PyCode_New(
    int, int, int, int, PyObject *, PyObject *, PyObject *, PyObject *,
    PyObject *, PyObject *, PyObject *, PyObject *, int, PyObject *);
  int PyCode_Addr2Line(PyCodeObject *, int);

  struct PyAddrPair {
    int ap_lower;
    int ap_upper;
  }

  int PyCode_CheckLineNumber(PyCodeObject* co, int lasti, PyAddrPair *bounds);
  version(Python_2_6_Or_Later){
      PyObject* PyCode_Optimize(PyObject *code, PyObject* consts,
                                      PyObject *names, PyObject *lineno_obj);
  }

  // Python-header-file: Include/pyarena.h:
  struct PyArena;

  version(Python_2_5_Or_Later){
      PyArena* PyArena_New();
      void PyArena_Free(PyArena*);

      void* PyArena_Malloc(PyArena*, size_t);
      int PyArena_AddPyObject(PyArena*, PyObject*);
  }

///////////////////////////////////////////////////////////////////////////////
// COMPILATION INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/node.h
  struct node {
    short	n_type;
    char	*n_str;
    int		n_lineno;
    version(Python_2_5_Or_Later){
    int		n_col_offset;
    }
    int		n_nchildren;
    node	*n_child;
  }
  node * PyNode_New(int type);
  int PyNode_AddChild(node *n, int type,
        char *str, int lineno, int col_offset);
  void PyNode_Free(node *n);
  void PyNode_ListTree(node *);

  // Python-header-file: Include/compile.h:
  PyCodeObject *PyNode_Compile(node *, const(char) *);

  struct PyFutureFeatures {
      version(Python_2_5_Or_Later){
      }else{
          int ff_found_docstring;
          int ff_last_linno;
      }
    int ff_features;
    version(Python_2_5_Or_Later){
        int ff_lineno;
    }
  }

  version(Python_2_5_Or_Later){
  }else{
      PyFutureFeatures *PyNode_Future(node *, const(char) *);
      PyCodeObject *PyNode_CompileFlags(node *, const(char) *, PyCompilerFlags *);
  }

  enum FUTURE_NESTED_SCOPES = "nested_scopes";
  enum FUTURE_GENERATORS = "generators";
  enum FUTURE_DIVISION = "division";
  version(Python_2_5_Or_Later){
      enum FUTURE_ABSOLUTE_IMPORT = "absolute_import";
      enum FUTURE_WITH_STATEMENT = "with_statement";
      version(Python_2_6_Or_Later){
          enum FUTURE_PRINT_FUNCTION = "print_function";
          enum FUTURE_UNICODE_LITERALS = "unicode_literals";
      }

      struct _mod; /* Declare the existence of this type */
      PyCodeObject * PyAST_Compile(_mod *, const(char) *, PyCompilerFlags *, PyArena *);
      PyFutureFeatures * PyFuture_FromAST(_mod *, const(char) *);

      // Python-header-file: Include/ast.h
      _mod* PyAST_FromNode(node*, PyCompilerFlags*, const(char)*, PyArena*);
  }


///////////////////////////////////////////////////////////////////////////////
// CODE EXECUTION INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/pythonrun.h:

  struct PyCompilerFlags {
    int cf_flags;
  }

  void Py_SetProgramName(char *);
  char *Py_GetProgramName();

  void Py_SetPythonHome(char *);
  char *Py_GetPythonHome();

  void Py_Initialize();
  void Py_InitializeEx(int);
  void Py_Finalize();
  int Py_IsInitialized();
  PyThreadState *Py_NewInterpreter();
  void Py_EndInterpreter(PyThreadState *);

  version(Python_2_5_Or_Later){
      int PyRun_AnyFile()(FILE *fp, const(char) *name) {
          return PyRun_AnyFileExFlags(fp, name, 0, null);
      }
      int PyRun_AnyFileEx()(FILE *fp, const(char) *name, int closeit) {
          return PyRun_AnyFileExFlags(fp, name, closeit, null);
      }
      int PyRun_AnyFileFlags()(FILE *fp, const(char) *name, PyCompilerFlags *flags) {
          return PyRun_AnyFileExFlags(fp, name, 0, flags);
      }
      int PyRun_SimpleString()(const(char) *s) {
          return PyRun_SimpleStringFlags(s, null);
      }
      int PyRun_SimpleFile()(FILE *f, const(char) *p) {
          return PyRun_SimpleFileExFlags(f, p, 0, null);
      }
      int PyRun_SimpleFileEx()(FILE *f, const(char) *p, int c) {
          return PyRun_SimpleFileExFlags(f, p, c, null);
      }
      int PyRun_InteractiveOne()(FILE *f, const(char) *p) {
          return PyRun_InteractiveOneFlags(f, p, null);
      }
      int PyRun_InteractiveLoop()(FILE *f, const(char) *p) {
          return PyRun_InteractiveLoopFlags(f, p, null);
      }
  }else{
      int PyRun_AnyFile(FILE *, const(char) *);
      int PyRun_AnyFileEx(FILE *, const(char) *,int);

      int PyRun_AnyFileFlags(FILE *, const(char) *, PyCompilerFlags *);
      int PyRun_SimpleString(const(char) *);
      int PyRun_SimpleFile(FILE *, const(char) *);
      int PyRun_SimpleFileEx(FILE *, const(char) *, int);
      int PyRun_InteractiveOne(FILE *, const(char) *);
      int PyRun_InteractiveLoop(FILE *, const(char) *);
  }

  int PyRun_AnyFileExFlags(FILE *, const(char) *, int, PyCompilerFlags *);

  int PyRun_SimpleStringFlags(const(char) *, PyCompilerFlags *);

  int PyRun_SimpleFileExFlags(FILE *,  const(char) *, int, PyCompilerFlags *);

  int PyRun_InteractiveOneFlags(FILE *, const(char) *, PyCompilerFlags *);
  int PyRun_InteractiveLoopFlags(FILE *, const(char) *, PyCompilerFlags *);

  version(Python_2_5_Or_Later){
      _mod* PyParser_ASTFromString(const(char) *, const(char) *, 
              int, PyCompilerFlags *, PyArena *);
      _mod* PyParser_ASTFromFile(FILE *, const(char) *, int, 
              char *, char *, PyCompilerFlags *, int *, PyArena *);
      node *PyParser_SimpleParseString()(const(char) *s, int b) {
          return PyParser_SimpleParseStringFlags(s, b, 0);
      }
      node *PyParser_SimpleParseFile()(FILE *f, const(char) *s, int b) {
          return PyParser_SimpleParseFileFlags(f, s, b, 0);
      }
  }else{
      node *PyParser_SimpleParseString(const(char) *, int);
      node *PyParser_SimpleParseFile(FILE *, const(char) *, int);
      node *PyParser_SimpleParseStringFlagsFilename(const(char) *, const(char) *, int, int);
  }

  node *PyParser_SimpleParseStringFlags(const(char) *, int, int);
  node *PyParser_SimpleParseFileFlags(FILE *, const(char) *,int, int);

  PyObject *PyRun_StringFlags( const(char) *, int, PyObject *, PyObject *, PyCompilerFlags *);
  version(Python_2_5_Or_Later){
      PyObject *PyRun_String()(const(char) *str, int s, PyObject *g, PyObject *l) {
          return PyRun_StringFlags(str, s, g, l, null);
      }
      PyObject *PyRun_File()(FILE *fp, const(char) *p, int s, PyObject *g, PyObject *l) {
          return PyRun_FileExFlags(fp, p, s, g, l, 0, null);
      }
      PyObject *PyRun_FileEx()(FILE *fp, const(char) *p, int s, PyObject *g, PyObject *l, int c) {
          return PyRun_FileExFlags(fp, p, s, g, l, c, null);
      }
      PyObject *PyRun_FileFlags()(FILE *fp, const(char) *p, int s, PyObject *g, 
              PyObject *l, PyCompilerFlags *flags) {
          return PyRun_FileExFlags(fp, p, s, g, l, 0, flags);
      }
      PyObject *Py_CompileString()(const(char) *str, const(char) *p, int s) {
          return Py_CompileStringFlags(str, p, s, null);
      }
  }else{
      PyObject *PyRun_String(const(char) *, int, PyObject *, PyObject *);
      PyObject *PyRun_File(FILE *, const(char) *, int, PyObject *, PyObject *);
      PyObject *PyRun_FileEx(FILE *, const(char) *, int, PyObject *, PyObject *, int);
      PyObject *PyRun_FileFlags(FILE *, const(char) *, int, PyObject *, PyObject *, 
              PyCompilerFlags *);
      PyObject *Py_CompileString(const(char) *, const(char) *, int);
  }

  PyObject *PyRun_FileExFlags(FILE *, const(char) *, int, PyObject *, PyObject *, int, PyCompilerFlags *);

  PyObject *Py_CompileStringFlags(const(char) *, const(char) *, int, PyCompilerFlags *);
  // Py_SymtableString is undocumented, so it's omitted here.

  void PyErr_Print();
  void PyErr_PrintEx(int);
  void PyErr_Display(PyObject *, PyObject *, PyObject *);

  int Py_AtExit(void function() func);

  void Py_Exit(int);

  int Py_FdIsInteractive(FILE *, const(char) *);

///////////////////////////////////////////////////////////////////////////////
// BOOTSTRAPPING INTERFACE (for embedding Python in D)
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/pythonrun.h:

  int Py_Main(int argc, char **argv);

  char *Py_GetProgramFullPath();
  char *Py_GetPrefix();
  char *Py_GetExecPrefix();
  char *Py_GetPath();

  const(char) *Py_GetVersion();
  const(char) *Py_GetPlatform();
  const(char) *Py_GetCopyright();
  const(char) *Py_GetCompiler();
  const(char) *Py_GetBuildInfo();
  version(Python_2_5_Or_Later){
      const(char) * _Py_svnversion();
      const(char) * Py_SubversionRevision();
      const(char) * Py_SubversionShortBranch();
  }

  version(Python_2_6_Or_Later){
      int PyByteArray_Init();
  }

  /////////////////////////////////////////////////////////////////////////////
  // ONE-TIME INITIALIZERS
  /////////////////////////////////////////////////////////////////////////////

  PyObject *_PyBuiltin_Init();
  PyObject *_PySys_Init();
  void _PyImport_Init();
  void _PyExc_Init();
  void _PyImportHooks_Init();
  int _PyFrame_Init();
  int _PyInt_Init();

  /////////////////////////////////////////////////////////////////////////////
  // FINALIZERS
  /////////////////////////////////////////////////////////////////////////////

  void _PyExc_Fini();
  void _PyImport_Fini();
  void PyMethod_Fini();
  void PyFrame_Fini();
  void PyCFunction_Fini();
  version(Python_2_6_Or_Later){
      void PyDict_Fini();
  }
  void PyTuple_Fini();
  void PyString_Fini();
  void PyInt_Fini();
  void PyFloat_Fini();
  void PyOS_FiniInterrupts();
  version(Python_2_6_Or_Later){
      void PyByteArray_Fini();
  }

  /////////////////////////////////////////////////////////////////////////////
  // VARIOUS (API members documented as having "no proper home")
  /////////////////////////////////////////////////////////////////////////////
  char *PyOS_Readline(FILE *, FILE *, char *);
  __gshared int function() PyOS_InputHook;
  __gshared char* function(FILE *, FILE *, char *) PyOS_ReadlineFunctionPointer;
  // _PyOS_ReadlineTState omitted.
  enum PYOS_STACK_MARGIN = 2048;
  // PyOS_CheckStack omitted.

  /////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  /////////////////////////////////////////////////////////////////////////////

  alias void function(int) PyOS_sighandler_t;
  PyOS_sighandler_t PyOS_getsig(int);
  PyOS_sighandler_t PyOS_setsig(int, PyOS_sighandler_t);


///////////////////////////////////////////////////////////////////////////////
// EVAL CALLS (documented as "Interface to random parts in ceval.c")
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/ceval.h:
  PyObject *PyEval_CallObjectWithKeywords(PyObject *, PyObject *, PyObject *);
  version(Python_2_5_Or_Later){
      PyObject *PyEval_CallObject()(PyObject *func, PyObject *arg) {
          return PyEval_CallObjectWithKeywords(func, arg, null);
      }
  }else{
      PyObject *PyEval_CallObject(PyObject *, PyObject *);
  }
  PyObject *PyEval_CallFunction(PyObject *obj, Char1 *format, ...);
  PyObject *PyEval_CallMethod(PyObject *obj, Char1 *methodname, Char1 *format, ...);

  void PyEval_SetProfile(Py_tracefunc, PyObject *);
  void PyEval_SetTrace(Py_tracefunc, PyObject *);

  Borrowed!PyObject* PyEval_GetBuiltins();
  Borrowed!PyObject* PyEval_GetGlobals();
  Borrowed!PyObject* PyEval_GetLocals();
  Borrowed!PyFrameObject* PyEval_GetFrame();
  int PyEval_GetRestricted();

  int PyEval_MergeCompilerFlags(PyCompilerFlags *cf);
  int Py_FlushLine();
  int Py_AddPendingCall(int function(void *) func, void *arg);
  int Py_MakePendingCalls();

  void Py_SetRecursionLimit(int);
  int Py_GetRecursionLimit();

  // The following API members are undocumented, so they're omitted here:
    // Py_EnterRecursiveCall
    // Py_LeaveRecursiveCall
    // _Py_CheckRecursiveCall
    // _Py_CheckRecursionLimit
    // _Py_MakeRecCheck

  Char1 *PyEval_GetFuncName(PyObject *);
  Char1 *PyEval_GetFuncDesc(PyObject *);

  PyObject *PyEval_GetCallStats(PyObject *);
  PyObject *PyEval_EvalFrame(PyFrameObject *);
  version(Python_2_5_Or_Later){
      PyObject *PyEval_EvalFrameEx(PyFrameObject *, int);
  }


///////////////////////////////////////////////////////////////////////////////
// SYSTEM MODULE INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/sysmodule.h:

  PyObject *PySys_GetObject(char *);
  int PySys_SetObject(char *, PyObject *);
  FILE *PySys_GetFile(char *, FILE *);
  void PySys_SetArgv(int, char **);
  version(Python_2_6_Or_Later){
      void PySys_SetArgvEx(int, char **, int);
  }
  void PySys_SetPath(char *);

  void PySys_WriteStdout(const(char) *format, ...);
  void PySys_WriteStderr(const(char) *format, ...);

  void PySys_ResetWarnOptions();
  void PySys_AddWarnOption(char *);
  version(Python_2_6_Or_Later){
      int PySys_HasWarnOptions();
  }


///////////////////////////////////////////////////////////////////////////////
// INTERRUPT INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/intrcheck.h:

  int PyOS_InterruptOccurred();
  void PyOS_InitInterrupts();
  void PyOS_AfterFork();


///////////////////////////////////////////////////////////////////////////////
// FRAME INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/frameobject.h:

  struct PyTryBlock {
    int b_type;
    int b_handler;
    int b_level;
  }

  struct PyFrameObject {
    mixin PyObject_VAR_HEAD;

    PyFrameObject *f_back;
    PyCodeObject *f_code;
    PyObject *f_builtins;
    PyObject *f_globals;
    PyObject *f_locals;
    PyObject **f_valuestack;
    PyObject **f_stacktop;
    PyObject *f_trace;
    PyObject *f_exc_type;
    PyObject *f_exc_value;
    PyObject *f_exc_traceback;
    PyThreadState *f_tstate;
    int f_lasti;
    int f_lineno;
    version(Python_2_5_Or_Later){
    }else{
        int f_restricted;
    }
    int f_iblock;
    PyTryBlock f_blockstack[CO_MAXBLOCKS];
    version(Python_2_5_Or_Later){
    }else{
        int f_nlocals;
        int f_ncells;
        int f_nfreevars;
        int f_stacksize;
    }
    PyObject *_f_localsplus[1];
    PyObject** f_localsplus()() {
      return _f_localsplus.ptr;
    }
  }

  // &PyFrame_Type is accessible via PyFrame_Type_p.
  // D translation of C macro:
  int PyFrame_Check()(PyObject *op) {
    return op.ob_type == PyFrame_Type_p;
  }
  version(Python_2_5_Or_Later){
      int PyFrame_IsRestricted()(PyFrameObject* f) {
          return f.f_builtins != f.f_tstate.interp.builtins;
      }
  }

  PyFrameObject *PyFrame_New(PyThreadState *, PyCodeObject *,
                             PyObject *, PyObject *);

  void PyFrame_BlockSetup(PyFrameObject *, int, int, int);
  PyTryBlock *PyFrame_BlockPop(PyFrameObject *);
  PyObject **PyFrame_ExtendStack(PyFrameObject *, int, int);

  void PyFrame_LocalsToFast(PyFrameObject *, int);
  void PyFrame_FastToLocals(PyFrameObject *);
  version(Python_2_6_Or_Later){
      int PyFrame_ClearFreeList();
  }


///////////////////////////////////////////////////////////////////////////////
// INTERPRETER STATE AND THREAD STATE INTERFACES
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/pystate.h:

  struct PyInterpreterState {
    PyInterpreterState *next;
    PyThreadState *tstate_head;

    PyObject *modules;
    PyObject *sysdict;
    PyObject *builtins;

    PyObject *codec_search_path;
    PyObject *codec_search_cache;
    PyObject *codec_error_registry;

    int dlopenflags;

    // XXX: Not sure what WITH_TSC refers to, or how to conditionalize it in D:
    //#ifdef WITH_TSC
    //  int tscdump;
    //#endif
  }

  alias int function(PyObject *, PyFrameObject *, int, PyObject *) Py_tracefunc;

  enum PyTrace_CALL   	= 0;
  enum PyTrace_EXCEPTION = 1;
  enum PyTrace_LINE 		= 2;
  enum PyTrace_RETURN 	= 3;
  enum PyTrace_C_CALL = 4;
  enum PyTrace_C_EXCEPTION = 5;
  enum PyTrace_C_RETURN = 6;

  struct PyThreadState {
    PyThreadState *next;
    PyInterpreterState *interp;

    PyFrameObject *frame;
    int recursion_depth;
    int tracing;
    int use_tracing;

    Py_tracefunc c_profilefunc;
    Py_tracefunc c_tracefunc;
    PyObject *c_profileobj;
    PyObject *c_traceobj;

    PyObject *curexc_type;
    PyObject *curexc_value;
    PyObject *curexc_traceback;

    PyObject *exc_type;
    PyObject *exc_value;
    PyObject *exc_traceback;

    PyObject *dict;

    int tick_counter;
    int gilstate_counter;

    PyObject *async_exc;
    C_long thread_id;
  }

  PyInterpreterState *PyInterpreterState_New();
  void PyInterpreterState_Clear(PyInterpreterState *);
  void PyInterpreterState_Delete(PyInterpreterState *);

  PyThreadState *PyThreadState_New(PyInterpreterState *);
  version(Python_2_6_Or_Later){
      PyThreadState * _PyThreadState_Prealloc(PyInterpreterState *);
      void _PyThreadState_Init(PyThreadState *);
  }
  void PyThreadState_Clear(PyThreadState *);
  void PyThreadState_Delete(PyThreadState *);
  void PyThreadState_DeleteCurrent();

  PyThreadState* PyThreadState_Get();
  PyThreadState* PyThreadState_Swap(PyThreadState *);
  Borrowed!PyObject* PyThreadState_GetDict();
  int PyThreadState_SetAsyncExc(C_long, PyObject *);

  enum PyGILState_STATE {PyGILState_LOCKED, PyGILState_UNLOCKED};

  PyGILState_STATE PyGILState_Ensure();
  void PyGILState_Release(PyGILState_STATE);
  PyThreadState *PyGILState_GetThisThreadState();
  PyInterpreterState *PyInterpreterState_Head();
  PyInterpreterState *PyInterpreterState_Next(PyInterpreterState *);
  PyThreadState *PyInterpreterState_ThreadHead(PyInterpreterState *);
  PyThreadState *PyThreadState_Next(PyThreadState *);

  alias PyFrameObject* function(PyThreadState *self_) PyThreadFrameGetter;

  // Python-header-file: Include/ceval.h:
  PyThreadState *PyEval_SaveThread();
  void PyEval_RestoreThread(PyThreadState *);

  int PyEval_ThreadsInitialized();
  void PyEval_InitThreads();
  void PyEval_AcquireLock();
  void PyEval_ReleaseLock();
  void PyEval_AcquireThread(PyThreadState *tstate);
  void PyEval_ReleaseThread(PyThreadState *tstate);
  void PyEval_ReInitThreads();

  // YYY: The following macros need to be implemented somehow, but DSR doesn't
  // think D's mixin feature is up to the job.
  // Py_BEGIN_ALLOW_THREADS
  // Py_BLOCK_THREADS
  // Py_UNBLOCK_THREADS
  // Py_END_ALLOW_THREADS


///////////////////////////////////////////////////////////////////////////////
// MODULE IMPORT INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/import.h:

  C_long PyImport_GetMagicNumber();
  PyObject *PyImport_ExecCodeModule(char *name, PyObject *co);
  PyObject *PyImport_ExecCodeModuleEx(char *name, PyObject *co, char *pathname);
  PyObject *PyImport_GetModuleDict();
  PyObject *PyImport_AddModule(Char1 *name);
  PyObject *PyImport_ImportModule(Char1 *name);

  version(Python_2_5_Or_Later){
      PyObject *PyImport_ImportModuleLevel(char *name,
              PyObject *globals, PyObject *locals, PyObject *fromlist, 
              int level);
  }
  version(Python_2_6_Or_Later){
      PyObject * PyImport_ImportModuleNoBlock(const(char)*);
  }else version(Python_2_5_Or_Later){
      PyObject *PyImport_ImportModuleEx()(char *n, PyObject *g, PyObject *l, 
              PyObject *f) {
          return PyImport_ImportModuleLevel(n, g, l, f, -1);
      }
  }else{
      PyObject *PyImport_ImportModuleEx(char *, PyObject *, PyObject *, PyObject *);
  }

  version(Python_2_6_Or_Later){
      PyObject * PyImport_GetImporter(PyObject *path);
  }
  PyObject *PyImport_Import(PyObject *name);
  PyObject *PyImport_ReloadModule(PyObject *m);
  void PyImport_Cleanup();
  int PyImport_ImportFrozenModule(char *);

  // The following API members are undocumented, so they're omitted here:
    // _PyImport_FindModule
    // _PyImport_IsScript
    // _PyImport_ReInitLock

  PyObject *_PyImport_FindExtension(char *, char *);
  PyObject *_PyImport_FixupExtension(char *, char *);

  struct _inittab {
    char *name;
    void function() initfunc;
  }

  // PyNullImporter_Type not available in d
  // PyImport_Inittab not available in d

  version(Python_2_7_Or_Later){
      alias const(char) Char2;
  }else{
      alias char Char2;
  }

  int PyImport_AppendInittab(Char2 *name, void function() initfunc);
  int PyImport_ExtendInittab(_inittab *newtab);

  struct _frozen {
    char *name;
    ubyte *code;
    int size;
  }

  // Omitted:
    // PyImport_FrozenModules


///////////////////////////////////////////////////////////////////////////////
// ABSTRACT OBJECT INTERFACE
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/abstract.h:

  // D translations of C macros:
  int PyObject_DelAttrString()(PyObject *o, Char1 *a) {
    return PyObject_SetAttrString(o, a, null);
  }
  int PyObject_DelAttr()(PyObject *o, PyObject *a) {
    return PyObject_SetAttr(o, a, null);
  }

  int PyObject_Cmp(PyObject *o1, PyObject *o2, int *result);

  /////////////////////////////////////////////////////////////////////////////
  // CALLABLES
  /////////////////////////////////////////////////////////////////////////////
  int PyCallable_Check(PyObject *o);

  PyObject *PyObject_Call(PyObject *callable_object, PyObject *args, PyObject *kw);
  PyObject *PyObject_CallObject(PyObject *callable_object, PyObject *args);
  version(Python_2_5_Or_Later){
  }else{
      PyObject *PyObject_CallFunction(PyObject *callable_object, char *format, ...);
      PyObject *PyObject_CallMethod(PyObject *o, char *m, char *format, ...);
  }
  PyObject *_PyObject_CallFunction_SizeT(PyObject *callable, char *format, ...);
  PyObject *_PyObject_CallMethod_SizeT(PyObject *o, char *name, char *format, ...);
  version(Python_2_5_Or_Later){
      alias _PyObject_CallFunction_SizeT PyObject_CallFunction;
      alias _PyObject_CallMethod_SizeT PyObject_CallMethod;
  }
  PyObject *PyObject_CallFunctionObjArgs(PyObject *callable, ...);
  PyObject *PyObject_CallMethodObjArgs(PyObject *o,PyObject *m, ...);

  /////////////////////////////////////////////////////////////////////////////
  // GENERIC
  /////////////////////////////////////////////////////////////////////////////
  PyObject *PyObject_Type(PyObject *o);

  /////////////////////////////////////////////////////////////////////////////
  // CONTAINERS
  /////////////////////////////////////////////////////////////////////////////

  Py_ssize_t PyObject_Size(PyObject *o);
  //int PyObject_Length(PyObject *o);
  alias PyObject_Size PyObject_Length;
  version(Python_2_6_Or_Later){
      Py_ssize_t _PyObject_LengthHint(PyObject*, Py_ssize_t);
  }else version(Python_2_5_Or_Later){
      Py_ssize_t _PyObject_LengthHint(PyObject*);
  }

  PyObject *PyObject_GetItem(PyObject *o, PyObject *key);
  int PyObject_SetItem(PyObject *o, PyObject *key, PyObject *v);
  int PyObject_DelItemString(PyObject *o, char *key);
  int PyObject_DelItem(PyObject *o, PyObject *key);

  int PyObject_AsCharBuffer(PyObject *obj, const(char) **buffer, Py_ssize_t *buffer_len);
  int PyObject_CheckReadBuffer(PyObject *obj);
  int PyObject_AsReadBuffer(PyObject *obj, void **buffer, Py_ssize_t *buffer_len);
  int PyObject_AsWriteBuffer(PyObject *obj, void **buffer, Py_ssize_t *buffer_len);

  version(Python_2_6_Or_Later){
    /* new buffer API */

      int PyObject_CheckBuffer()(PyObject *obj){
          return (obj.ob_type.tp_as_buffer !is null) &&
              PyType_HasFeature(obj.ob_type, Py_TPFLAGS_HAVE_NEWBUFFER) &&
              (obj.ob_type.tp_as_buffer.bf_getbuffer !is null);
      }

    /* Return 1 if the getbuffer function is available, otherwise
       return 0 */

     int PyObject_GetBuffer(PyObject *obj, Py_buffer *view,
                                        int flags);

    /* This is a C-API version of the getbuffer function call.  It checks
       to make sure object has the required function pointer and issues the
       call.  Returns -1 and raises an error on failure and returns 0 on
       success
    */


     void* PyBuffer_GetPointer(Py_buffer *view, Py_ssize_t *indices);

    /* Get the memory area pointed to by the indices for the buffer given.
       Note that view->ndim is the assumed size of indices
    */

     int PyBuffer_SizeFromFormat(const(char) *);

    /* Return the implied itemsize of the data-format area from a
       struct-style description */



     int PyBuffer_ToContiguous(void *buf, Py_buffer *view,
                                           Py_ssize_t len, char fort);

     int PyBuffer_FromContiguous(Py_buffer *view, void *buf,
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

     int PyObject_CopyData(PyObject *dest, PyObject *src);

    /* Copy the data from the src buffer to the buffer of destination
     */

     int PyBuffer_IsContiguous(Py_buffer *view, char fort);


     void PyBuffer_FillContiguousStrides(int ndims,
                                                    Py_ssize_t *shape,
                                                    Py_ssize_t *strides,
                                                    int itemsize,
                                                    char fort);

    /*  Fill the strides array with byte-strides of a contiguous
        (Fortran-style if fort is 'F' or C-style otherwise)
        array of the given shape with the given number of bytes
        per element.
    */

     int PyBuffer_FillInfo(Py_buffer *view, PyObject *o, void *buf,
                                       Py_ssize_t len, int readonly,
                                       int flags);

    /* Fills in a buffer-info structure correctly for an exporter
       that can only share a contiguous chunk of memory of
       "unsigned bytes" of the given length. Returns 0 on success
       and -1 (with raising an error) on error.
     */

     void PyBuffer_Release(Py_buffer *view);

       /* Releases a Py_buffer obtained from getbuffer ParseTuple's s*.
    */

     PyObject* PyObject_Format(PyObject* obj,
                                            PyObject *format_spec);
       /*
     Takes an arbitrary object and returns the result of
     calling obj.__format__(format_spec).
       */

  }

  /////////////////////////////////////////////////////////////////////////////
  // ITERATORS
  /////////////////////////////////////////////////////////////////////////////
  PyObject *PyObject_GetIter(PyObject *);

  // D translation of C macro:
  int PyIter_Check()(PyObject *obj) {
    return PyType_HasFeature(obj.ob_type, Py_TPFLAGS_HAVE_ITER)
        && obj.ob_type.tp_iternext != null;
  }

  PyObject *PyIter_Next(PyObject *);

  /////////////////////////////////////////////////////////////////////////////
  // NUMBERS
  /////////////////////////////////////////////////////////////////////////////

  int PyNumber_Check(PyObject *o);

  PyObject *PyNumber_Add(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_Subtract(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_Multiply(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_Divide(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_FloorDivide(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_TrueDivide(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_Remainder(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_Divmod(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_Power(PyObject *o1, PyObject *o2, PyObject *o3);
  PyObject *PyNumber_Negative(PyObject *o);
  PyObject *PyNumber_Positive(PyObject *o);
  PyObject *PyNumber_Absolute(PyObject *o);
  PyObject *PyNumber_Invert(PyObject *o);
  PyObject *PyNumber_Lshift(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_Rshift(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_And(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_Xor(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_Or(PyObject *o1, PyObject *o2);

  version(Python_2_5_Or_Later){
      int PyIndex_Check()(PyObject* obj) {
          return obj.ob_type.tp_as_number !is null &&
              PyType_HasFeature(obj.ob_type, Py_TPFLAGS_HAVE_INDEX) &&
              obj.ob_type.tp_as_number.nb_index !is null;
      }
      PyObject *PyNumber_Index(PyObject *o);
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

     PyObject * _PyNumber_ConvertIntegralToInt(
         PyObject *integral,
         const(char)* error_format);
  }

  PyObject *PyNumber_Int(PyObject *o);
  PyObject *PyNumber_Long(PyObject *o);
  PyObject *PyNumber_Float(PyObject *o);

  PyObject *PyNumber_InPlaceAdd(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_InPlaceSubtract(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_InPlaceMultiply(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_InPlaceDivide(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_InPlaceFloorDivide(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_InPlaceTrueDivide(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_InPlaceRemainder(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_InPlacePower(PyObject *o1, PyObject *o2, PyObject *o3);
  PyObject *PyNumber_InPlaceLshift(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_InPlaceRshift(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_InPlaceAnd(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_InPlaceXor(PyObject *o1, PyObject *o2);
  PyObject *PyNumber_InPlaceOr(PyObject *o1, PyObject *o2);

  version(Python_2_6_Or_Later){
     PyObject* PyNumber_ToBase(PyObject *n, int base);

       /*
     Returns the integer n converted to a string with a base, with a base
     marker of 0b, 0o or 0x prefixed if applicable.
     If n is not an int object, it is converted with PyNumber_Index first.
       */
  }

  /////////////////////////////////////////////////////////////////////////////
  // SEQUENCES
  /////////////////////////////////////////////////////////////////////////////

  int PySequence_Check(PyObject *o);
  Py_ssize_t PySequence_Size(PyObject *o);
  alias PySequence_Size PySequence_Length;

  PyObject *PySequence_Concat(PyObject *o1, PyObject *o2);
  PyObject *PySequence_Repeat(PyObject *o, Py_ssize_t count);
  PyObject *PySequence_GetItem(PyObject *o, Py_ssize_t i);
  PyObject *PySequence_GetSlice(PyObject *o, Py_ssize_t i1, Py_ssize_t i2);

  int PySequence_SetItem(PyObject *o, Py_ssize_t i, PyObject *v);
  int PySequence_DelItem(PyObject *o, Py_ssize_t i);
  int PySequence_SetSlice(PyObject *o, Py_ssize_t i1, Py_ssize_t i2, PyObject *v);
  int PySequence_DelSlice(PyObject *o, Py_ssize_t i1, Py_ssize_t i2);

  PyObject *PySequence_Tuple(PyObject *o);
  PyObject *PySequence_List(PyObject *o);

  PyObject *PySequence_Fast(PyObject *o,  const(char)* m);
  // D translations of C macros:
  Py_ssize_t PySequence_Fast_GET_SIZE()(PyObject *o) {
    return PyList_Check(o) ? cast(Py_ssize_t) PyList_GET_SIZE(o) :
        cast(Py_ssize_t) PyTuple_GET_SIZE(o);
  }
  PyObject *PySequence_Fast_GET_ITEM()(PyObject *o, Py_ssize_t i) {
    return PyList_Check(o) ? PyList_GET_ITEM(o, i) : PyTuple_GET_ITEM(o, i);
  }
  PyObject *PySequence_ITEM()(PyObject *o, Py_ssize_t i) {
    return o.ob_type.tp_as_sequence.sq_item(o, i);
  }
  PyObject **PySequence_Fast_ITEMS()(PyObject *sf) {
    return
        PyList_Check(sf) ?
            (cast(PyListObject *)sf).ob_item
          : (cast(PyTupleObject *)sf).ob_item
      ;
  }

  Py_ssize_t PySequence_Count(PyObject *o, PyObject *value);
  int PySequence_Contains(PyObject *seq, PyObject *ob);

  int PY_ITERSEARCH_COUNT    = 1;
  int PY_ITERSEARCH_INDEX    = 2;
  int PY_ITERSEARCH_CONTAINS = 3;

  Py_ssize_t _PySequence_IterSearch(PyObject *seq, PyObject *obj, int operation);
  //int PySequence_In(PyObject *o, PyObject *value);
  alias PySequence_Contains PySequence_In;
  Py_ssize_t PySequence_Index(PyObject *o, PyObject *value);

  PyObject * PySequence_InPlaceConcat(PyObject *o1, PyObject *o2);
  PyObject * PySequence_InPlaceRepeat(PyObject *o, Py_ssize_t count);

  /////////////////////////////////////////////////////////////////////////////
  // MAPPINGS
  /////////////////////////////////////////////////////////////////////////////
  int PyMapping_Check(PyObject *o);
  Py_ssize_t PyMapping_Size(PyObject *o);
  //int PyMapping_Length(PyObject *o);
  alias PyMapping_Size PyMapping_Length;

  // D translations of C macros:
  int PyMapping_DelItemString()(PyObject *o, char *k) {
    return PyObject_DelItemString(o, k);
  }
  int PyMapping_DelItem()(PyObject *o, PyObject *k) {
    return PyObject_DelItem(o, k);
  }

  int PyMapping_HasKeyString(PyObject *o, char *key);
  int PyMapping_HasKey(PyObject *o, PyObject *key);

  // D translations of C macros:
  PyObject *PyMapping_Keys()(PyObject *o) {
    return PyObject_CallMethod(o, "keys".dup.ptr, null);
  }
  PyObject *PyMapping_Values()(PyObject *o) {
    return PyObject_CallMethod(o, "values".dup.ptr, null);
  }
  PyObject *PyMapping_Items()(PyObject *o) {
    return PyObject_CallMethod(o, "items".dup.ptr, null);
  }

  PyObject *PyMapping_GetItemString(PyObject *o, char *key);
  int PyMapping_SetItemString(PyObject *o, char *key, PyObject *value);

  /////////////////////////////////////////////////////////////////////////////
  // GENERIC
  /////////////////////////////////////////////////////////////////////////////
  int PyObject_IsInstance(PyObject *object, PyObject *typeorclass);
  int PyObject_IsSubclass(PyObject *object, PyObject *typeorclass);

  version(Python_2_6_Or_Later){
      int _PyObject_RealIsInstance(PyObject *inst, PyObject *cls);

      int _PyObject_RealIsSubclass(PyObject *derived, PyObject *cls);
  }


///////////////////////////////////////////////////////////////////////////////
// OBJECT CREATION AND GARBAGE COLLECTION
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/objimpl.h:

  void * PyObject_Malloc(size_t);
  void * PyObject_Realloc(void *, size_t);
  void PyObject_Free(void *);

  Borrowed!PyObject* PyObject_Init(PyObject*, PyTypeObject*);

  Borrowed!PyVarObject* PyObject_InitVar(PyVarObject*,
                           PyTypeObject *, Py_ssize_t);
  /* Without macros, DSR knows of no way to translate PyObject_New and
   * PyObject_NewVar to D; the lower-level _PyObject_New and _PyObject_NewVar
   * will have to suffice.
   * YYY: Perhaps D's mixins could be used?
   * KGM: Pfft, it's a simple template function. */
  PyObject * _PyObject_New(PyTypeObject *);
  PyVarObject * _PyObject_NewVar(PyTypeObject *, Py_ssize_t);
  type* PyObject_New(type)(PyTypeObject* o) {
    return cast(type*)_PyObject_New(o);
  }
  type* PyObject_NewVar(type)(PyTypeObject* o, Py_ssize_t n) {
    return cast(type*)_PyObject_NewVar(o, n);
  }


  C_long PyGC_Collect();

  // D translations of C macros:
  int PyType_IS_GC()(PyTypeObject *t) {
    return PyType_HasFeature(t, Py_TPFLAGS_HAVE_GC);
  }
  int PyObject_IS_GC()(PyObject *o) {
    return PyType_IS_GC(o.ob_type)
        && (o.ob_type.tp_is_gc == null || o.ob_type.tp_is_gc(o));
  }
  PyVarObject *_PyObject_GC_Resize(PyVarObject *, Py_ssize_t);
  // XXX: Can D mixins allows trans of PyObject_GC_Resize?
  // KGM: No, but template functions can.
  type* PyObject_GC_Resize(type) (PyVarObject *op, Py_ssize_t n) {
	return cast(type*)_PyObject_GC_Resize(op, n);
  }


  union PyGC_Head {
    struct gc {
      PyGC_Head *gc_next;
      PyGC_Head *gc_prev;
      Py_ssize_t gc_refs;
    }
    real dummy; // XXX: C type was long double; is this equiv?
  }

  // Numerous macro definitions that appear in objimpl.h at this point are not
  // document.  They appear to be for internal use, so they're omitted here.

  PyObject *_PyObject_GC_Malloc(size_t);
  PyObject *_PyObject_GC_New(PyTypeObject *);
  PyVarObject *_PyObject_GC_NewVar(PyTypeObject *, Py_ssize_t);
  void PyObject_GC_Track(void *);
  void PyObject_GC_UnTrack(void *);
  void PyObject_GC_Del(void *);

  // XXX: DSR currently knows of no way to translate the PyObject_GC_New and
  // PyObject_GC_NewVar macros to D.
  // KGM does, though.
  type* PyObject_GC_New(type) (PyTypeObject* o) {
    return cast(type*)_PyObject_GC_New(o);
  }
  type* PyObject_GC_NewVar(type) (PyTypeObject* o, Py_ssize_t n) {
    return cast(type*)_PyObject_GC_NewVar(o, n);
  }

  /////////////////////////////////////////////////////////////////////////////
  // MISCELANEOUS
  /////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/pydebug.h:
  void Py_FatalError(char *message);


///////////////////////////////////////////////////////////////////////////////
// cStringIO (Must be explicitly imported with PycString_IMPORT().)
///////////////////////////////////////////////////////////////////////////////
// Python-header-file: Include/cStringIO.h:

PycStringIO_CAPI *PycStringIO = null;

PycStringIO_CAPI *PycString_IMPORT()() {
  if (PycStringIO == null) {
    PycStringIO = cast(PycStringIO_CAPI *)
      PyCObject_Import("cStringIO".dup.ptr, "cStringIO_CAPI".dup.ptr);
  }
  return PycStringIO;
}

struct PycStringIO_CAPI {
  int function(PyObject *, char **, Py_ssize_t) cread;
  int function(PyObject *, char **) creadline;
  int function(PyObject *, Char1 *, Py_ssize_t) cwrite;
  PyObject* function(PyObject *) cgetvalue;
  PyObject* function(int) NewOutput;
  PyObject* function(PyObject *) NewInput;
  PyTypeObject *InputType;
  PyTypeObject *OutputType;
}

// D translations of C macros:
int PycStringIO_InputCheck()(PyObject *o) {
  return o.ob_type == PycStringIO.InputType;
}
int PycStringIO_OutputCheck()(PyObject *o) {
  return o.ob_type == PycStringIO.OutputType;
}


///////////////////////////////////////////////////////////////////////////////
// datetime (Must be explicitly imported with PycString_IMPORT().)
///////////////////////////////////////////////////////////////////////////////
// Python-header-file: Include/datetime.h:

enum _PyDateTime_DATE_DATASIZE = 4;
enum _PyDateTime_TIME_DATASIZE = 6;
enum _PyDateTime_DATETIME_DATASIZE = 10;

struct PyDateTime_Delta {
  mixin PyObject_HEAD;

  C_long hashcode;
  int days;
  int seconds;
  int microseconds;
}

struct PyDateTime_TZInfo {
  mixin PyObject_HEAD;
}

template _PyTZINFO_HEAD() {
  mixin PyObject_HEAD;
  C_long hashcode;
  ubyte hastzinfo;
}

struct _PyDateTime_BaseTZInfo {
  mixin _PyTZINFO_HEAD;
}

template _PyDateTime_TIMEHEAD() {
  mixin _PyTZINFO_HEAD;
  ubyte data[_PyDateTime_TIME_DATASIZE];
}

struct _PyDateTime_BaseTime {
  mixin _PyDateTime_TIMEHEAD;
}

struct PyDateTime_Time {
  mixin _PyDateTime_TIMEHEAD;
  PyObject *tzinfo;
}

struct PyDateTime_Date {
  mixin _PyTZINFO_HEAD;
  ubyte data[_PyDateTime_DATE_DATASIZE];
}

template _PyDateTime_DATETIMEHEAD() {
  mixin _PyTZINFO_HEAD;
  ubyte data[_PyDateTime_DATETIME_DATASIZE];
}

struct _PyDateTime_BaseDateTime {
  mixin _PyDateTime_DATETIMEHEAD;
}

struct PyDateTime_DateTime {
  mixin _PyDateTime_DATETIMEHEAD;
  PyObject *tzinfo;
}

// D translations of C macros:
int PyDateTime_GET_YEAR()(PyObject *o) {
  PyDateTime_Date *ot = cast(PyDateTime_Date *) o;
  return (ot.data[0] << 8) | ot.data[1];
}
int PyDateTime_GET_MONTH()(PyObject *o) {
  PyDateTime_Date *ot = cast(PyDateTime_Date *) o;
  return ot.data[2];
}
int PyDateTime_GET_DAY()(PyObject *o) {
  PyDateTime_Date *ot = cast(PyDateTime_Date *) o;
  return ot.data[3];
}

int PyDateTime_DATE_GET_HOUR()(PyObject *o) {
  PyDateTime_DateTime *ot = cast(PyDateTime_DateTime *) o;
  return ot.data[4];
}
int PyDateTime_DATE_GET_MINUTE()(PyObject *o) {
  PyDateTime_DateTime *ot = cast(PyDateTime_DateTime *) o;
  return ot.data[5];
}
int PyDateTime_DATE_GET_SECOND()(PyObject *o) {
  PyDateTime_DateTime *ot = cast(PyDateTime_DateTime *) o;
  return ot.data[6];
}
int PyDateTime_DATE_GET_MICROSECOND()(PyObject *o) {
  PyDateTime_DateTime *ot = cast(PyDateTime_DateTime *) o;
  return (ot.data[7] << 16) | (ot.data[8] << 8) | ot.data[9];
}

int PyDateTime_TIME_GET_HOUR()(PyObject *o) {
  PyDateTime_Time *ot = cast(PyDateTime_Time *) o;
  return ot.data[0];
}
int PyDateTime_TIME_GET_MINUTE()(PyObject *o) {
  PyDateTime_Time *ot = cast(PyDateTime_Time *) o;
  return ot.data[1];
}
int PyDateTime_TIME_GET_SECOND()(PyObject *o) {
  PyDateTime_Time *ot = cast(PyDateTime_Time *) o;
  return ot.data[2];
}
int PyDateTime_TIME_GET_MICROSECOND()(PyObject *o) {
  PyDateTime_Time *ot = cast(PyDateTime_Time *) o;
  return (ot.data[3] << 16) | (ot.data[4] << 8) | ot.data[5];
}

struct PyDateTime_CAPI {
  PyTypeObject *DateType;
  PyTypeObject *DateTimeType;
  PyTypeObject *TimeType;
  PyTypeObject *DeltaType;
  PyTypeObject *TZInfoType;

  PyObject* function(int, int, int, PyTypeObject*) Date_FromDate;
  PyObject* function(int, int, int, int, int, int, int,
          PyObject*, PyTypeObject*) DateTime_FromDateAndTime;
  PyObject* function(int, int, int, int, PyObject*, PyTypeObject*) Time_FromTime;
  PyObject* function(int, int, int, int, PyTypeObject*) Delta_FromDelta;

  PyObject* function(PyObject*, PyObject*, PyObject*) DateTime_FromTimestamp;
  PyObject* function(PyObject*, PyObject*) Date_FromTimestamp;
}

enum DATETIME_API_MAGIC = 0x414548d5;
PyDateTime_CAPI *PyDateTimeAPI;

PyDateTime_CAPI *PyDateTime_IMPORT()() {
  if (PyDateTimeAPI == null) {
    PyDateTimeAPI = cast(PyDateTime_CAPI *)
      PyCObject_Import("datetime".dup.ptr, "datetime_CAPI".dup.ptr);
  }
  return PyDateTimeAPI;
}

// D translations of C macros:
int PyDate_Check()(PyObject *op) {
  return PyObject_TypeCheck(op, PyDateTimeAPI.DateType);
}
int PyDate_CheckExact()(PyObject *op) {
  return op.ob_type == PyDateTimeAPI.DateType;
}
int PyDateTime_Check()(PyObject *op) {
  return PyObject_TypeCheck(op, PyDateTimeAPI.DateTimeType);
}
int PyDateTime_CheckExact()(PyObject *op) {
  return op.ob_type == PyDateTimeAPI.DateTimeType;
}
int PyTime_Check()(PyObject *op) {
  return PyObject_TypeCheck(op, PyDateTimeAPI.TimeType);
}
int PyTime_CheckExact()(PyObject *op) {
  return op.ob_type == PyDateTimeAPI.TimeType;
}
int PyDelta_Check()(PyObject *op) {
  return PyObject_TypeCheck(op, PyDateTimeAPI.DeltaType);
}
int PyDelta_CheckExact()(PyObject *op) {
  return op.ob_type == PyDateTimeAPI.DeltaType;
}
int PyTZInfo_Check()(PyObject *op) {
  return PyObject_TypeCheck(op, PyDateTimeAPI.TZInfoType);
}
int PyTZInfo_CheckExact()(PyObject *op) {
  return op.ob_type == PyDateTimeAPI.TZInfoType;
}

PyObject *PyDate_FromDate()(int year, int month, int day) {
  return PyDateTimeAPI.Date_FromDate(year, month, day, PyDateTimeAPI.DateType);
}
PyObject *PyDateTime_FromDateAndTime()(int year, int month, int day, int hour, int min, int sec, int usec) {
  return PyDateTimeAPI.DateTime_FromDateAndTime(year, month, day, hour,
    min, sec, usec, Py_None, PyDateTimeAPI.DateTimeType);
}
PyObject *PyTime_FromTime()(int hour, int minute, int second, int usecond) {
  return PyDateTimeAPI.Time_FromTime(hour, minute, second, usecond,
    Py_None, PyDateTimeAPI.TimeType);
}
PyObject *PyDelta_FromDSU()(int days, int seconds, int useconds) {
  return PyDateTimeAPI.Delta_FromDelta(days, seconds, useconds, 1,
    PyDateTimeAPI.DeltaType);
}
PyObject *PyDateTime_FromTimestamp()(PyObject *args) {
  return PyDateTimeAPI.DateTime_FromTimestamp(
    cast(PyObject*) (PyDateTimeAPI.DateTimeType), args, null);
}
PyObject *PyDate_FromTimestamp()(PyObject *args) {
  return PyDateTimeAPI.Date_FromTimestamp(
    cast(PyObject*) (PyDateTimeAPI.DateType), args);
}


///////////////////////////////////////////////////////////////////////////////
// Interface to execute compiled code
///////////////////////////////////////////////////////////////////////////////
// Python-header-file: Include/eval.h:
PyObject *PyEval_EvalCode(PyCodeObject *, PyObject *, PyObject *);
PyObject *PyEval_EvalCodeEx(
    PyCodeObject *co,
    PyObject *globals,
    PyObject *locals,
    PyObject **args, int argc,
    PyObject **kwds, int kwdc,
    PyObject **defs, int defc,
    PyObject *closure
  );
PyObject *_PyEval_CallTracing(PyObject *func, PyObject *args);


///////////////////////////////////////////////////////////////////////////////
// Generator object interface
///////////////////////////////////////////////////////////////////////////////
// Python-header-file: Include/genobject.h:
struct PyGenObject {
  mixin PyObject_HEAD;
  PyFrameObject *gi_frame;
  int gi_running;
  version(Python_2_6_Or_Later){
      /* The code object backing the generator */
      PyObject *gi_code;
  }
  PyObject *gi_weakreflist;
}

// &PyGen_Type is accessible via PyGen_Type_p.
// D translations of C macros:
int PyGen_Check()(PyObject *op) {
  return PyObject_TypeCheck(op, PyGen_Type_p);
}
int PyGen_CheckExact()(PyObject *op) {
  return op.ob_type == PyGen_Type_p;
}

PyObject *PyGen_New(PyFrameObject *);
int PyGen_NeedsFinalizing(PyGenObject *);


///////////////////////////////////////////////////////////////////////////////
// Interface for marshal.c
///////////////////////////////////////////////////////////////////////////////
// Python-header-file: Include/marshal.h:

version(Python_2_5_Or_Later){
    enum Py_MARSHAL_VERSION = 2;
} else version(Python_2_4_Or_Later){
    enum Py_MARSHAL_VERSION = 1;
}

void PyMarshal_WriteLongToFile(C_long, FILE *, int);
void PyMarshal_WriteObjectToFile(PyObject *, FILE *, int);
PyObject * PyMarshal_WriteObjectToString(PyObject *, int);

C_long PyMarshal_ReadLongFromFile(FILE *);
int PyMarshal_ReadShortFromFile(FILE *);
PyObject *PyMarshal_ReadObjectFromFile(FILE *);
PyObject *PyMarshal_ReadLastObjectFromFile(FILE *);
PyObject *PyMarshal_ReadObjectFromString(char *, Py_ssize_t);


///////////////////////////////////////////////////////////////////////////////
// Platform-independent wrappers around strod, etc (probably not needed in D)
///////////////////////////////////////////////////////////////////////////////
// Python-header-file: Include/pystrtod.h:

double PyOS_ascii_strtod(const(char) *str, char **ptr);
double PyOS_ascii_atof(const(char) *str);
char *PyOS_ascii_formatd(char *buffer, size_t buf_len, const(char) *format, double d);


///////////////////////////////////////////////////////////////////////////////
// INTERFACE TO THE STDLIB 'THREAD' MODULE
///////////////////////////////////////////////////////////////////////////////
// Python-header-file: Include/pythread.h:

alias void * PyThread_type_lock;
alias void * PyThread_type_sema;

void PyThread_init_thread();
C_long PyThread_start_new_thread(void function(void *), void *);
void PyThread_exit_thread();
void PyThread__PyThread_exit_thread();
C_long PyThread_get_thread_ident();

PyThread_type_lock PyThread_allocate_lock();
void PyThread_free_lock(PyThread_type_lock);
int PyThread_acquire_lock(PyThread_type_lock, int);
enum WAIT_LOCK = 1;
enum NOWAIT_LOCK = 0;
void PyThread_release_lock(PyThread_type_lock);

version(Python_2_5_Or_Later){
    size_t PyThread_get_stacksize();
    int PyThread_set_stacksize(size_t);
}

void PyThread_exit_prog(int);
void PyThread__PyThread_exit_prog(int);

int PyThread_create_key();
void PyThread_delete_key(int);
int PyThread_set_key_value(int, void *);
void *PyThread_get_key_value(int);
void PyThread_delete_key_value(int key);


///////////////////////////////////////////////////////////////////////////////
// SET INTERFACE (built-in types set and frozenset)
///////////////////////////////////////////////////////////////////////////////
// Python-header-file: Include/setobject.h:

version(Python_2_5_Or_Later){
    enum PySet_MINSIZE = 8;

    struct setentry {
        C_long hash;
        PyObject *key;
    }
}

struct PySetObject {
    mixin PyObject_HEAD;

    version(Python_2_5_Or_Later){
        Py_ssize_t fill;
        Py_ssize_t used;

        Py_ssize_t mask;

        setentry *table;
        setentry* function(PySetObject *so, PyObject *key, C_long hash) lookup;
        setentry smalltable[PySet_MINSIZE];
    }else{
        PyObject *data;
    }

    C_long hash;
    PyObject *weakreflist;
}

// &PySet_Type is accessible via PySet_Type_p.
// &PyFrozenSet_Type is accessible via PyFrozenSet_Type_p.

// D translations of C macros:
int PyFrozenSet_CheckExact()(PyObject *ob) {
    return ob.ob_type == PyFrozenSet_Type_p;
}
int PyAnySet_CheckExact()(PyObject* ob) {
    return ob.ob_type == PySet_Type_p || ob.ob_type == PyFrozenSet_Type_p;
}
int PyAnySet_Check()(PyObject *ob) {
    return (
         ob.ob_type == PySet_Type_p
      || ob.ob_type == PyFrozenSet_Type_p
      || PyType_IsSubtype(ob.ob_type, PySet_Type_p)
      || PyType_IsSubtype(ob.ob_type, PyFrozenSet_Type_p)
    );
}
version(Python_2_6_Or_Later){
    bool PySet_Check()(PyObject *ob) {
        return (ob.ob_type == &PySet_Type || 
                PyType_IsSubtype(ob.ob_type, &PySet_Type));
    }
    bool PyFrozenSet_Check()(PyObject *ob) {
        return (ob.ob_type == &PyFrozenSet_Type || 
                PyType_IsSubtype(ob.ob_type, &PyFrozenSet_Type));
    }
}

version(Python_2_5_Or_Later){
    PyObject *PySet_New(PyObject *);
    PyObject *PyFrozenSet_New(PyObject *);
    Py_ssize_t PySet_Size(PyObject *anyset);
    Py_ssize_t PySet_GET_SIZE()(PyObject* so) {
        return (cast(PySetObject*)so).used;
    }
    int PySet_Clear(PyObject *set);
    int PySet_Contains(PyObject *anyset, PyObject *key);
    int PySet_Discard(PyObject *set, PyObject *key);
    int PySet_Add(PyObject *set, PyObject *key);
    int _PySet_Next(PyObject *set, Py_ssize_t *pos, PyObject **entry);
    PyObject *PySet_Pop(PyObject *set);
    int _PySet_Update(PyObject *set, PyObject *iterable);
}

///////////////////////////////////////////////////////////////////////////////
// Interface to map C struct members to Python object attributes
///////////////////////////////////////////////////////////////////////////////
// Python-header-file: Include/structmember.h:

struct PyMemberDef {
  char *name;
  int type;
  Py_ssize_t offset;
  int flags;
  char *doc;
}

enum T_SHORT = 0;
enum T_INT = 1;
enum T_LONG = 2;
enum T_FLOAT = 3;
enum T_DOUBLE = 4;
enum T_STRING = 5;
enum T_OBJECT = 6;
enum T_CHAR = 7;
enum T_BYTE = 8;
enum T_UBYTE = 9;
enum T_USHORT = 10;
enum T_UINT = 11;
enum T_ULONG = 12;
enum T_STRING_INPLACE = 13;
version(Python_2_6_Or_Later){
    enum T_BOOL = 14;
}
enum T_OBJECT_EX = 16;
version(Python_2_5_Or_Later){
    enum T_LONGLONG = 17;
    enum T_ULONGLONG = 18;
}
version(Python_2_6_Or_Later){
    enum T_PYSSIZET = 19;
}

enum READONLY = 1;
alias READONLY RO;
enum READ_RESTRICTED = 2;
enum WRITE_RESTRICTED = 4;
enum RESTRICTED = (READ_RESTRICTED | WRITE_RESTRICTED);

PyObject *PyMember_GetOne(Char1 *, PyMemberDef *);
int PyMember_SetOne(char *, PyMemberDef *, PyObject *);


///////////////////////////////////////////////////////////////////////////////
// INTERFACE FOR TUPLE-LIKE "STRUCTURED SEQUENCES"
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/structseq.h:

struct PyStructSequence_Field {
  char *name;
  char *doc;
}

struct PyStructSequence_Desc {
  char *name;
  char *doc;
  PyStructSequence_Field *fields;
  int n_in_sequence;
}

// XXX: What about global var PyStructSequence_UnnamedField?

void PyStructSequence_InitType(PyTypeObject *type, PyStructSequence_Desc *desc);
PyObject *PyStructSequence_New(PyTypeObject* type);

struct PyStructSequence {
  mixin PyObject_VAR_HEAD;
  // DSR:XXX:LAYOUT:
  // Will the D layout for a 1-obj array be the same as the C layout?  I
  // think the D array will be larger.
  PyObject *_ob_item[1];
  PyObject** ob_item()() {
    return _ob_item.ptr;
  }
}

// D translation of C macro:
PyObject *PyStructSequence_SET_ITEM()(PyObject *op, int i, PyObject *v) {
  PyStructSequence *ot = cast(PyStructSequence *) op;
  ot.ob_item[i] = v;
  return v;
}


///////////////////////////////////////////////////////////////////////////////
// UTILITY FUNCTION RELATED TO TIMEMODULE.C
///////////////////////////////////////////////////////////////////////////////
  // Python-header-file: Include/timefuncs.h:

  time_t _PyTime_DoubleToTimet(double x);



} /* extern (C) */


/* The following global variables will contain pointers to certain immutable
 * Python objects that Python/C API programmers expect.
 *
 * In order to make these global variables from the Python library available
 * to D, I tried the extern workaround documented at:
 *   http://www.digitalmars.com/d/archives/digitalmars/D/15427.html
 * but it didn't work (Python crashed when attempting to manipulate the
 * pointers).
 * Besides, in some cases, canonical use of the Python/C API *requires* macros.
 * I ultimately resorted to traversing the Python module structure and loading
 * pointers to the required objects manually (see
 * python_support.d/_loadPythonSupport). */

private {

/* Singletons: */
PyObject* m_Py_None;
PyObject* m_Py_NotImplemented;
PyObject* m_Py_Ellipsis;
PyObject* m_Py_True;
PyObject* m_Py_False;

/* Types: */
PyTypeObject* m_PyType_Type_p;
PyTypeObject* m_PyBaseObject_Type_p;
PyTypeObject* m_PySuper_Type_p;

PyTypeObject* m_PyNone_Type_p;

PyTypeObject* m_PyUnicode_Type_p;
PyTypeObject* m_PyInt_Type_p;
PyTypeObject* m_PyBool_Type_p;
PyTypeObject* m_PyLong_Type_p;
PyTypeObject* m_PyFloat_Type_p;
PyTypeObject* m_PyComplex_Type_p;
PyTypeObject* m_PyRange_Type_p;
PyTypeObject* m_PyBaseString_Type_p;
PyTypeObject* m_PyString_Type_p;
PyTypeObject* m_PyBuffer_Type_p;
PyTypeObject* m_PyTuple_Type_p;
PyTypeObject* m_PyList_Type_p;
PyTypeObject* m_PyDict_Type_p;
PyTypeObject* m_PyEnum_Type_p;
PyTypeObject* m_PyReversed_Type_p;
PyTypeObject* m_PyCFunction_Type_p;
PyTypeObject* m_PyModule_Type_p;
PyTypeObject* m_PyFunction_Type_p;
PyTypeObject* m_PyClassMethod_Type_p;
PyTypeObject* m_PyStaticMethod_Type_p;
PyTypeObject* m_PyClass_Type_p;
PyTypeObject* m_PyInstance_Type_p;
PyTypeObject* m_PyMethod_Type_p;
PyTypeObject* m_PyFile_Type_p;
PyTypeObject* m_PyCode_Type_p;
PyTypeObject* m_PyFrame_Type_p;
PyTypeObject* m_PyGen_Type_p;
PyTypeObject* m_PySet_Type_p;
PyTypeObject* m_PyFrozenSet_Type_p;

/* YYY: Python's default encoding can actually be changed during program
 * with sys.setdefaultencoding, so perhaps it would be better not to expose
 * this at all: */
char* m_Py_FileSystemDefaultEncoding;

PyTypeObject* m_PyCObject_Type_p;
PyTypeObject* m_PyTraceBack_Type_p;
PyTypeObject* m_PySlice_Type_p;
PyTypeObject* m_PyCell_Type_p;
PyTypeObject* m_PySeqIter_Type_p;
PyTypeObject* m_PyCallIter_Type_p;
/* PyWrapperDescr_Type_p omitted. */
PyTypeObject* m_PyProperty_Type_p;

PyTypeObject* m__PyWeakref_RefType_p;
PyTypeObject* m__PyWeakref_ProxyType_p;
PyTypeObject* m__PyWeakref_CallableProxyType_p;

/* Exceptions: */
PyObject* m_PyExc_Exception;
PyObject* m_PyExc_StopIteration;
PyObject* m_PyExc_StandardError;
PyObject* m_PyExc_ArithmeticError;
PyObject* m_PyExc_LookupError;

PyObject* m_PyExc_AssertionError;
PyObject* m_PyExc_AttributeError;
PyObject* m_PyExc_EOFError;
PyObject* m_PyExc_FloatingPointError;
PyObject* m_PyExc_EnvironmentError;
PyObject* m_PyExc_IOError;
PyObject* m_PyExc_OSError;
PyObject* m_PyExc_ImportError;
PyObject* m_PyExc_IndexError;
PyObject* m_PyExc_KeyError;
PyObject* m_PyExc_KeyboardInterrupt;
PyObject* m_PyExc_MemoryError;
PyObject* m_PyExc_NameError;
PyObject* m_PyExc_OverflowError;
PyObject* m_PyExc_RuntimeError;
PyObject* m_PyExc_NotImplementedError;
PyObject* m_PyExc_SyntaxError;
PyObject* m_PyExc_IndentationError;
PyObject* m_PyExc_TabError;
PyObject* m_PyExc_ReferenceError;
PyObject* m_PyExc_SystemError;
PyObject* m_PyExc_SystemExit;
PyObject* m_PyExc_TypeError;
PyObject* m_PyExc_UnboundLocalError;
PyObject* m_PyExc_UnicodeError;
PyObject* m_PyExc_UnicodeEncodeError;
PyObject* m_PyExc_UnicodeDecodeError;
PyObject* m_PyExc_UnicodeTranslateError;
PyObject* m_PyExc_ValueError;
PyObject* m_PyExc_ZeroDivisionError;
version (Windows) {
  PyObject* m_PyExc_WindowsError;
}
/* PyExc_MemoryErrorInst omitted. */

PyObject* m_PyExc_Warning;
PyObject* m_PyExc_UserWarning;
PyObject* m_PyExc_DeprecationWarning;
PyObject* m_PyExc_PendingDeprecationWarning;
PyObject* m_PyExc_SyntaxWarning;
/* PyExc_OverflowWarning omitted, because it'll go away in Python 2.5. */
PyObject* m_PyExc_RuntimeWarning;
PyObject* m_PyExc_FutureWarning;

PyObject *eval()(string code) {
    PyObject *pyGlobals = Py_INCREF(PyEval_GetGlobals()); /* borrowed ref */
    scope(exit) Py_DECREF(pyGlobals);
    PyObject *res = PyRun_String(toStringz(code), Py_eval_input,
        pyGlobals, pyGlobals
    ); /* New ref, or NULL on error. */
    if (res == null) {
        throw new Exception("XXX: write error message; make PythonException D class");
    }

    return res;
}

PyObject* m_builtins, m_types, m_weakref;

} /* end private */

// These template functions will lazily-load the various singleton objects,
// removing the need for a "load" function that does it all at once.
typeof(Ptr) lazy_sys(alias Ptr, string name) () {
    if (Ptr is null) {
        PyObject* sys_modules = PyImport_GetModuleDict();
        Ptr = cast(typeof(Ptr)) PyDict_GetItemString(sys_modules, 
                toStringz(name));
    }
    assert (Ptr !is null, "python.d couldn't load " ~ name ~ " attribute!");
    return Ptr;
}

alias lazy_sys!(m_builtins, "__builtin__") builtins;
alias lazy_sys!(m_types, "types") types;
alias lazy_sys!(m_weakref, "weakref") weakref;

@property typeof(Ptr) lazy_load(alias from, alias Ptr, string name) () {
    if (Ptr is null) {
        Ptr = cast(typeof(Ptr)) PyObject_GetAttrString(from(), toStringz(name));
    }
    assert (Ptr !is null, "python.d couldn't load " ~ name ~ " attribute!");
    return Ptr;
}

typeof(Ptr) lazy_eval(alias Ptr, string code) () {
    if (Ptr is null) {
        Ptr = cast(typeof(Ptr)) eval(code);
    }
    assert (Ptr !is null, "python.d couldn't lazily eval something...");
    return Ptr;
}


//void _loadPythonSupport() {
//static this() {
//printf("[_loadPythonSupport started (Py_None is null: %d)]\n", Py_None is null);

/+
  PyObject *sys_modules = PyImport_GetModuleDict();

  PyObject *builtins = PyDict_GetItemString(sys_modules, "__builtin__");
  assert (builtins != null);
  PyObject *types = PyDict_GetItemString(sys_modules, "types");
  assert (types != null);

  PyObject *weakref = PyImport_ImportModule("weakref");
  assert (weakref != null);
+/

  /* Since Python never unloads an extension module once it has been loaded,
   * we make no attempt to release these references. */

  /* Singletons: */
alias lazy_load!(builtins, m_Py_None, "None") Py_None;
alias lazy_load!(builtins, m_Py_NotImplemented, "NotImplemented") Py_NotImplemented;
alias lazy_load!(builtins, m_Py_Ellipsis, "Ellipsis") Py_Ellipsis;
alias lazy_load!(builtins, m_Py_True, "True") Py_True;
alias lazy_load!(builtins, m_Py_False, "False") Py_False;

  /* Types: */
alias lazy_load!(builtins, m_PyType_Type_p, "type") PyType_Type_p;
alias lazy_load!(builtins, m_PyBaseObject_Type_p, "object") PyBaseObject_Type_p;
alias lazy_load!(builtins, m_PySuper_Type_p, "super") PySuper_Type_p;

alias lazy_load!(types, m_PyNone_Type_p, "NoneType") PyNone_Type_p;

alias lazy_load!(builtins, m_PyUnicode_Type_p, "unicode") PyUnicode_Type_p;
alias lazy_load!(builtins, m_PyInt_Type_p, "int") PyInt_Type_p;
alias lazy_load!(builtins, m_PyBool_Type_p, "bool") PyBool_Type_p;
alias lazy_load!(builtins, m_PyLong_Type_p, "long") PyLong_Type_p;
alias lazy_load!(builtins, m_PyFloat_Type_p, "float") PyFloat_Type_p;
alias lazy_load!(builtins, m_PyComplex_Type_p, "complex") PyComplex_Type_p;
alias lazy_load!(builtins, m_PyRange_Type_p, "xrange") PyRange_Type_p;
alias lazy_load!(builtins, m_PyBaseString_Type_p, "basestring") PyBaseString_Type_p;
alias lazy_load!(builtins, m_PyString_Type_p, "str") PyString_Type_p;
alias lazy_load!(builtins, m_PyBuffer_Type_p, "buffer") PyBuffer_Type_p;
alias lazy_load!(builtins, m_PyTuple_Type_p, "tuple") PyTuple_Type_p;
alias lazy_load!(builtins, m_PyList_Type_p, "list") PyList_Type_p;
alias lazy_load!(builtins, m_PyDict_Type_p, "dict") PyDict_Type_p;
alias lazy_load!(builtins, m_PyEnum_Type_p, "enumerate") PyEnum_Type_p;
alias lazy_load!(builtins, m_PyReversed_Type_p, "reversed") PyReversed_Type_p;

alias lazy_load!(types, m_PyCFunction_Type_p, "BuiltinFunctionType") PyCFunction_Type_p;
alias lazy_load!(types, m_PyModule_Type_p, "ModuleType") PyModule_Type_p;
alias lazy_load!(types, m_PyFunction_Type_p, "FunctionType") PyFunction_Type_p;

alias lazy_load!(builtins, m_PyClassMethod_Type_p, "classmethod") PyClassMethod_Type_p;
alias lazy_load!(builtins, m_PyStaticMethod_Type_p, "staticmethod") PyStaticMethod_Type_p;

alias lazy_load!(types, m_PyClass_Type_p, "ClassType") PyClass_Type_p;
alias lazy_load!(types, m_PyInstance_Type_p, "InstanceType") PyInstance_Type_p;
alias lazy_load!(types, m_PyMethod_Type_p, "MethodType") PyMethod_Type_p;

alias lazy_load!(builtins, m_PyFile_Type_p, "file") PyFile_Type_p;

const(char)* Py_FileSystemDefaultEncoding()() {
    if (m_Py_FileSystemDefaultEncoding is null) {
        m_Py_FileSystemDefaultEncoding = PyUnicode_GetDefaultEncoding();
        assert (m_Py_FileSystemDefaultEncoding !is null,
            "python.d couldn't load PyUnicode_DefaultEncoding attribute!");
    }
    return m_Py_FileSystemDefaultEncoding;
}

  /* Python's "CObject" type is intended to serve as an opaque handle for
   * passing a C void pointer from C code to Python code and back. */
PyTypeObject* PyCObject_Type_p()() {
    if (m_PyCObject_Type_p is null) {
        PyObject *aCObject = PyCObject_FromVoidPtr(null, null);
        m_PyCObject_Type_p = cast(PyTypeObject *) PyObject_Type(aCObject);
        Py_DECREF(aCObject);
    }
    return m_PyCObject_Type_p;
}

alias lazy_load!(types, m_PyTraceBack_Type_p, "TracebackType") PyTraceBack_Type_p;
alias lazy_load!(types, m_PySlice_Type_p, "SliceType") PySlice_Type_p;

PyTypeObject* PyCell_Type_p()() {
    if (m_PyCell_Type_p is null) {
        PyObject *cell = PyCell_New(null);
        assert (cell != null);
        m_PyCell_Type_p = cast(PyTypeObject *) PyObject_Type(cell);
        assert (PyCell_Type_p != null);
        Py_DECREF(cell);
    }
    return m_PyCell_Type_p;
}

alias lazy_eval!(m_PySeqIter_Type_p, "type(iter(''))") PySeqIter_Type_p;
alias lazy_eval!(m_PyCallIter_Type_p, "type(iter(lambda: None, None))") PyCallIter_Type_p;

  /* PyWrapperDescr_Type_p omitted. */
alias lazy_load!(builtins, m_PyProperty_Type_p, "property") PyProperty_Type_p;

alias lazy_load!(weakref, m__PyWeakref_RefType_p, "ReferenceType") _PyWeakref_RefType_p;
alias lazy_load!(weakref, m__PyWeakref_ProxyType_p, "ProxyType") _PyWeakref_ProxyType_p;
alias lazy_load!(weakref, m__PyWeakref_CallableProxyType_p, "CallableProxyType") _PyWeakref_CallableProxyType_p;

alias lazy_load!(types, m_PyCode_Type_p, "CodeType") PyCode_Type_p;
alias lazy_load!(types, m_PyFrame_Type_p, "FrameType") PyFrame_Type_p;
alias lazy_load!(types, m_PyGen_Type_p, "GeneratorType") PyGen_Type_p;

alias lazy_load!(builtins, m_PySet_Type_p, "set") PySet_Type_p;
alias lazy_load!(builtins, m_PyFrozenSet_Type_p, "frozenset") PyFrozenSet_Type_p;

  /* Exceptions: */
alias lazy_load!(builtins, m_PyExc_ArithmeticError, "ArithmeticError") PyExc_ArithmeticError;
alias lazy_load!(builtins, m_PyExc_AssertionError, "AssertionError") PyExc_AssertionError;
alias lazy_load!(builtins, m_PyExc_AttributeError, "AttributeError") PyExc_AttributeError;
alias lazy_load!(builtins, m_PyExc_DeprecationWarning, "DeprecationWarning") PyExc_DeprecationWarning;
alias lazy_load!(builtins, m_PyExc_EOFError, "EOFError") PyExc_EOFError;
alias lazy_load!(builtins, m_PyExc_EnvironmentError, "EnvironmentError") PyExc_EnvironmentError;
alias lazy_load!(builtins, m_PyExc_Exception, "Exception") PyExc_Exception;
alias lazy_load!(builtins, m_PyExc_FloatingPointError, "FloatingPointError") PyExc_FloatingPointError;
alias lazy_load!(builtins, m_PyExc_FutureWarning, "FutureWarning") PyExc_FutureWarning;
alias lazy_load!(builtins, m_PyExc_IOError, "IOError") PyExc_IOError;
alias lazy_load!(builtins, m_PyExc_ImportError, "ImportError") PyExc_ImportError;
alias lazy_load!(builtins, m_PyExc_IndentationError, "IndentationError") PyExc_IndentationError;
alias lazy_load!(builtins, m_PyExc_IndexError, "IndexError") PyExc_IndexError;
alias lazy_load!(builtins, m_PyExc_KeyError, "KeyError") PyExc_KeyError;
alias lazy_load!(builtins, m_PyExc_KeyboardInterrupt, "KeyboardInterrupt") PyExc_KeyboardInterrupt;
alias lazy_load!(builtins, m_PyExc_LookupError, "LookupError") PyExc_LookupError;
alias lazy_load!(builtins, m_PyExc_MemoryError, "MemoryError") PyExc_MemoryError;
  /* PyExc_MemoryErrorInst omitted. */
alias lazy_load!(builtins, m_PyExc_NameError, "NameError") PyExc_NameError;
alias lazy_load!(builtins, m_PyExc_NotImplementedError, "NotImplementedError") PyExc_NotImplementedError;
alias lazy_load!(builtins, m_PyExc_OSError, "OSError") PyExc_OSError;
alias lazy_load!(builtins, m_PyExc_OverflowError, "OverflowError") PyExc_OverflowError;
alias lazy_load!(builtins, m_PyExc_PendingDeprecationWarning, "PendingDeprecationWarning") PyExc_PendingDeprecationWarning;
alias lazy_load!(builtins, m_PyExc_ReferenceError, "ReferenceError") PyExc_ReferenceError;
alias lazy_load!(builtins, m_PyExc_RuntimeError, "RuntimeError") PyExc_RuntimeError;
alias lazy_load!(builtins, m_PyExc_RuntimeWarning, "RuntimeWarning") PyExc_RuntimeWarning;
alias lazy_load!(builtins, m_PyExc_StandardError, "StandardError") PyExc_StandardError;
alias lazy_load!(builtins, m_PyExc_StopIteration, "StopIteration") PyExc_StopIteration;
alias lazy_load!(builtins, m_PyExc_SyntaxError, "SyntaxError") PyExc_SyntaxError;
alias lazy_load!(builtins, m_PyExc_SyntaxWarning, "SyntaxWarning") PyExc_SyntaxWarning;
alias lazy_load!(builtins, m_PyExc_SystemError, "SystemError") PyExc_SystemError;
alias lazy_load!(builtins, m_PyExc_SystemExit, "SystemExit") PyExc_SystemExit;
alias lazy_load!(builtins, m_PyExc_TabError, "TabError") PyExc_TabError;
alias lazy_load!(builtins, m_PyExc_TypeError, "TypeError") PyExc_TypeError;
alias lazy_load!(builtins, m_PyExc_UnboundLocalError, "UnboundLocalError") PyExc_UnboundLocalError;
alias lazy_load!(builtins, m_PyExc_UnicodeDecodeError, "UnicodeDecodeError") PyExc_UnicodeDecodeError;
alias lazy_load!(builtins, m_PyExc_UnicodeEncodeError, "UnicodeEncodeError") PyExc_UnicodeEncodeError;
alias lazy_load!(builtins, m_PyExc_UnicodeError, "UnicodeError") PyExc_UnicodeError;
alias lazy_load!(builtins, m_PyExc_UnicodeTranslateError, "UnicodeTranslateError") PyExc_UnicodeTranslateError;
alias lazy_load!(builtins, m_PyExc_UserWarning, "UserWarning") PyExc_UserWarning;
alias lazy_load!(builtins, m_PyExc_ValueError, "ValueError") PyExc_ValueError;
alias lazy_load!(builtins, m_PyExc_Warning, "Warning") PyExc_Warning;

version (Windows) {
    alias lazy_load!(builtins, m_PyExc_WindowsError, "WindowsError") PyExc_WindowsError;
}

alias lazy_load!(builtins, m_PyExc_ZeroDivisionError, "ZeroDivisionError") PyExc_ZeroDivisionError;

// Python-header-file: Modules/arraymodule.c:

struct arraydescr{
    int typecode;
    int itemsize;
    PyObject* function(arrayobject*, Py_ssize_t) getitem;
    int function(arrayobject*, Py_ssize_t, PyObject*) setitem;
}

struct arrayobject {
    mixin PyObject_VAR_HEAD;
    ubyte* ob_item;
    Py_ssize_t allocated;
    arraydescr* ob_descr;
    PyObject* weakreflist; /* List of weak references */
} 
