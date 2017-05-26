/**
  Mirror _setobject.h

  Set object interface
  */
module deimos.python.setobject;

import core.stdc.stdio;
import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/setobject.h:

version(Python_2_5_Or_Later){
    /// Availability: >= 2.5
    enum PySet_MINSIZE = 8;

    /// Availability: >= 2.5
    struct setentry {
        /** cached hash code for the entry key */
        Py_hash_t hash;
        /// _
        PyObject* key;
    }
}

/**
This data structure is shared by set and frozenset objects.

 Invariants for frozensets:
     data is immutable.
     hash is the hash of the frozenset or -1 if not computed yet.
 Invariants for sets:
     hash is -1

subclass of PyObject.
*/

version(Python_3_5_Or_Later) {
    struct PySetObject {
        mixin PyObject_HEAD;

        /// Availability: >= 2.5
        Py_ssize_t fill;
        /// Availability: >= 2.5
        Py_ssize_t used;

        /** The table contains mask + 1 slots, and that's a power of 2.
         * We store the mask instead of the size because the mask is more
         * frequently needed.
         */
        Py_ssize_t mask;

        /** table points to smalltable for small tables, else to
         * additional malloc'ed memory.  table is never NULL!  This rule
         * saves repeated runtime null-tests.
         */
        setentry* table;

        /// _
        Py_hash_t hash;

        /// _
        Py_ssize_t finger;

        /// _
        setentry[PySet_MINSIZE] smalltable;

        /// _
        PyObject* weakreflist;
    }
}else version(Python_3_2_Or_Later) {
    struct PySetObject {
        mixin PyObject_HEAD;

        /// Availability: >= 2.5
        Py_ssize_t fill;
        /// Availability: >= 2.5
        Py_ssize_t used;

        /** The table contains mask + 1 slots, and that's a power of 2.
         * We store the mask instead of the size because the mask is more
         * frequently needed.
         */
        Py_ssize_t mask;

        /** table points to smalltable for small tables, else to
         * additional malloc'ed memory.  table is never NULL!  This rule
         * saves repeated runtime null-tests.
         */
        setentry* table;

        /// _
        setentry* function(PySetObject* so, PyObject* key, Py_hash_t hash) lookup;
        /// _
        Py_hash_t hash;

        /// _
        setentry[PySet_MINSIZE] smalltable;
        /// _
        PyObject* weakreflist;
    }
}else version(Python_2_5_Or_Later) {
    struct PySetObject {
        mixin PyObject_HEAD;

        /// Availability: >= 2.5
        Py_ssize_t fill;
        /// Availability: >= 2.5
        Py_ssize_t used;

        /** The table contains mask + 1 slots, and that's a power of 2.
         * We store the mask instead of the size because the mask is more
         * frequently needed.
         */
        Py_ssize_t mask;

        /** table points to smalltable for small tables, else to
         * additional malloc'ed memory.  table is never NULL!  This rule
         * saves repeated runtime null-tests.
         */
        setentry* table;

        /// _
        setentry* function(PySetObject* so, PyObject* key, C_long hash) lookup;
        /// _
        setentry[PySet_MINSIZE] smalltable;

        /** only used by frozenset objects */
        C_long hash;
        /** List of weak references */
        PyObject* weakreflist;
    }

}else {
    struct PySetObject {
        mixin PyObject_HEAD;

        /// Availability: 2.4
        PyObject* data;

        /** only used by frozenset objects */
        C_long hash;
        /** List of weak references */
        PyObject* weakreflist;
    }
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PySet_Type");
/// _
mixin(PyAPI_DATA!"PyTypeObject PyFrozenSet_Type");
/// _
mixin(PyAPI_DATA!"PyTypeObject PySetIter_Type");

// D translations of C macros:
/// _
int PyFrozenSet_CheckExact()(PyObject* ob) {
    return Py_TYPE(ob) == &PyFrozenSet_Type;
}
/// _
int PyAnySet_CheckExact()(PyObject* ob) {
    return Py_TYPE(ob) == &PySet_Type || Py_TYPE(ob) == &PyFrozenSet_Type;
}
/// _
int PyAnySet_Check()(PyObject* ob) {
    return (
         Py_TYPE(ob) == &PySet_Type
      || Py_TYPE(ob) == &PyFrozenSet_Type
      || PyType_IsSubtype(Py_TYPE(ob), &PySet_Type)
      || PyType_IsSubtype(Py_TYPE(ob), &PyFrozenSet_Type)
    );
}
version(Python_2_6_Or_Later){
    /// Availability: >= 2.6
    bool PySet_Check()(PyObject* ob) {
        return (Py_TYPE(ob) == &PySet_Type ||
                PyType_IsSubtype(Py_TYPE(ob), &PySet_Type));
    }
    /// Availability: >= 2.6
    bool PyFrozenSet_Check()(PyObject* ob) {
        return (Py_TYPE(ob) == &PyFrozenSet_Type ||
                PyType_IsSubtype(Py_TYPE(ob), &PyFrozenSet_Type));
    }
}

version(Python_2_5_Or_Later){
    /// Availability: >= 2.5
    PyObject* PySet_New(PyObject*);
    /// Availability: >= 2.5
    PyObject* PyFrozenSet_New(PyObject*);
    /// Availability: >= 2.5
    Py_ssize_t PySet_Size(PyObject* anyset);
    /// Availability: >= 2.5
    Py_ssize_t PySet_GET_SIZE()(PyObject* so) {
        return (cast(PySetObject*)so).used;
    }
    /// Availability: >= 2.5
    int PySet_Clear(PyObject* set);
    /// Availability: >= 2.5
    int PySet_Contains(PyObject* anyset, PyObject* key);
    /// Availability: >= 2.5
    int PySet_Discard(PyObject* set, PyObject* key);
    /// Availability: >= 2.5
    int PySet_Add(PyObject* set, PyObject* key);
    /// Availability: >= 2.5
    int _PySet_Next(PyObject* set, Py_ssize_t *pos, PyObject** entry);
    /// Availability: >= 2.5
    int _PySet_NextEntry(PyObject* set, Py_ssize_t* pos, PyObject** key, Py_hash_t* hash);
    /// Availability: >= 2.5
    PyObject* PySet_Pop(PyObject* set);
    /// Availability: >= 2.5
    int _PySet_Update(PyObject* set, PyObject* iterable);
}

version(Python_3_5_Or_Later) {
    /// Availability: >= 3.5
    int PySet_ClearFreeList();
}

version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    void _PySet_DebugMallocStats(FILE* out_);
}

