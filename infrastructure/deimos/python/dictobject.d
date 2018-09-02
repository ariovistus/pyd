/**
  Mirror _dictobject.h
  */
module deimos.python.dictobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.pythonrun;
import core.stdc.stdio;

extern(C):
// Python-header-file: Include/dictobject.h:

/** PyDict_MINSIZE is the minimum size of a dictionary.  This many slots are
 * allocated directly in the dict object (in the ma_smalltable member).
 * It must be a power of 2, and at least 4.  8 allows dicts with no more
 * than 5 active entries to live in ma_smalltable (and so avoid an
 * additional malloc); instrumentation suggested this suffices for the
 * majority of dicts (consisting mostly of usually-small instance dicts and
 * usually-small dicts created to pass keyword arguments).
 */
enum int PyDict_MINSIZE = 8;

version(Python_3_4_Or_Later) {
}else{
	/// Availability: ??
	struct PyDictEntry {
	    /** Cached hash code of me_key.  Note that hash codes are C longs.
	     * We have to use Py_ssize_t instead because dict_popitem() abuses
	     * me_hash to hold a search finger.
	     */
	    version(Python_3_2_Or_Later) {
		Py_hash_t me_hash;
	    }else version(Python_2_5_Or_Later) {
		Py_ssize_t me_hash;
	    }else{
		C_long me_hash;
	    }
	    /// _
	    PyObject* me_key;
	    /// _
	    PyObject* me_value;
	}
}

/**
To ensure the lookup algorithm terminates, there must be at least one Unused
slot (NULL key) in the table.
The value ma_fill is the number of non-NULL keys (sum of Active and Dummy);
ma_used is the number of non-NULL, non-dummy keys (== the number of non-NULL
values == the number of Active items).
To avoid slowing down lookups on a near-full table, we resize the table when
it's two-thirds full.

*/

/// subclass of PyObject
version(Python_3_4_Or_Later) {
    struct PyDictKeysObject {
        // ??!
    }

    struct PyDictObject {
        mixin PyObject_HEAD;
        /** number of items in the dictionary */
        Py_ssize_t ma_used;

        version(Python_3_6_Or_Later) {
            /** Dictionary version: globally unique, value change each time 
              the dictionary is modified */
            ulong ma_version_tag;
        }
        PyDictKeysObject* ma_keys;

        /** If ma_values is NULL, the table is "combined": 
          keys and values are stored in ma_keys.

          If ma_values is not NULL, the table is split:
          keys are stored in ma_keys and values are stored in ma_values */
        PyObject** ma_values;
    }
}else{
    struct PyDictObject{
        mixin PyObject_HEAD;

        /// _
        Py_ssize_t ma_fill;
        /// _
        Py_ssize_t ma_used;
        /** The table contains ma_mask + 1 slots, and that's a power of 2.
         * We store the mask instead of the size because the mask is more
         * frequently needed.
         */
        Py_ssize_t ma_mask;
        /** ma_table points to ma_smalltable for small tables, else to
         * additional malloc'ed memory.  ma_table is never NULL!  This rule
         * saves repeated runtime null-tests in the workhorse getitem and
         * setitem calls.
         */
        PyDictEntry* ma_table;
        /// _
        PyDictEntry* function(PyDictObject* mp, PyObject* key, Py_hash_t hash)
            ma_lookup;
        /// _
        PyDictEntry[PyDict_MINSIZE] ma_smalltable;
    }
}

version(Python_3_5_Or_Later) {
    struct _PyDictViewObject {
        mixin PyObject_HEAD;
        PyDictObject* dv_dict;
    }
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PyDict_Type");
version(Python_2_7_Or_Later) {
    /// Availability: >= 2.7
    mixin(PyAPI_DATA!"PyTypeObject PyDictIterKey_Type");
    /// Availability: >= 2.7
    mixin(PyAPI_DATA!"PyTypeObject PyDictIterValue_Type");
    /// Availability: >= 2.7
    mixin(PyAPI_DATA!"PyTypeObject PyDictIterItem_Type");
    /// Availability: >= 2.7
    mixin(PyAPI_DATA!"PyTypeObject PyDictKeys_Type");
    /// Availability: >= 2.7
    mixin(PyAPI_DATA!"PyTypeObject PyDictItems_Type");
    /// Availability: >= 2.7
    mixin(PyAPI_DATA!"PyTypeObject PyDictValues_Type");
}

// D translation of C macro:
/// _
int PyDict_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, &PyDict_Type);
}
// D translation of C macro:
/// _
int PyDict_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyDict_Type;
}

version(Python_2_7_Or_Later) {
    /// Availability: >= 2.7
    int PyDictKeys_Check()(PyObject* op) {
        return Py_TYPE(op) == &PyDictKeys_Type;
    }
    /// Availability: >= 2.7
    int PyDictItems_Check()(PyObject* op) {
        return Py_TYPE(op) == &PyDictItems_Type;
    }
    /// Availability: >= 2.7
    int PyDictValues_Check()(PyObject* op) {
        return Py_TYPE(op) == &PyDictValues_Type;
    }
    /// Availability: >= 2.7
    int PyDictViewSet_Check()(PyObject* op) {
        return PyDictKeys_Check(op) || PyDictItems_Check(op);
    }
}

/// _
PyObject* PyDict_New();
/// _
PyObject_BorrowedRef* PyDict_GetItem(PyObject* mp, PyObject* key);
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    Borrowed!PyObject* PyDict_GetItemWithError(PyObject* mp, PyObject* key);
}
/// _
int PyDict_SetItem(PyObject* mp, PyObject* key, PyObject* item);
/// _
int PyDict_DelItem(PyObject* mp, PyObject* key);
/// _
void PyDict_Clear(PyObject* mp);
/// _
int PyDict_Next(PyObject* mp, Py_ssize_t* pos, PyObject_BorrowedRef** key, PyObject_BorrowedRef** value);
version(Python_2_5_Or_Later) {
    /// Availability: >= 2.5
    int _PyDict_Next(
            PyObject* mp, Py_ssize_t* pos, Borrowed!PyObject** key,
            Borrowed!PyObject** value, Py_hash_t* hash);
}
/// _
PyObject* PyDict_Keys(PyObject* mp);
/// _
PyObject* PyDict_Values(PyObject* mp);
/// _
PyObject* PyDict_Items(PyObject* mp);
/// _
Py_ssize_t PyDict_Size(PyObject* mp);
/// _
PyObject* PyDict_Copy(PyObject* mp);
/// _
int PyDict_Contains(PyObject* mp, PyObject* key);
version(Python_3_7_Or_Later) {
    Py_ssize_t PyDict_GET_SIZE()(PyObject* mp) {
        return (cast(PyDictObject*)mp).ma_used;
    }
}
version(Python_2_5_Or_Later) {
    /// Availability: >= 2.5
    int _PyDict_Contains(PyObject* mp, PyObject* key, Py_hash_t* hash);
}
version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    PyObject* _PyDict_NewPresized(Py_ssize_t minused);
}
version(Python_2_7_Or_Later) {
    /// Availability: >= 2.7
    void _PyDict_MaybeUntrack(PyObject* mp);
}
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    int _PyDict_HasOnlyStringKeys(PyObject* mp);
}

/** PyDict_Update(mp, other) is equivalent to PyDict_Merge(mp, other, 1). */
int PyDict_Update(PyObject* mp, PyObject* other);
/** PyDict_Merge updates/merges from a mapping object (an object that
   supports PyMapping_Keys() and PyObject_GetItem()).  If override is true,
   the last occurrence of a key wins, else the first.  The Python
   dict.update(other) is equivalent to PyDict_Merge(dict, other, 1).
*/
int PyDict_Merge(PyObject* mp, PyObject* other, int override_);
/** PyDict_MergeFromSeq2 updates/merges from an iterable object producing
   iterable objects of length 2.  If override is true, the last occurrence
   of a key wins, else the first.  The Python dict constructor dict(seq2)
   is equivalent to dict={}; PyDict_MergeFromSeq(dict, seq2, 1).
*/
int PyDict_MergeFromSeq2(PyObject* d, PyObject* seq2, int override_);

/// _
PyObject_BorrowedRef* PyDict_GetItemString(PyObject* dp, const(char)* key);
/// _
int PyDict_SetItemString(PyObject* dp, const(char)* key, PyObject* item);
/// _
int PyDict_DelItemString(PyObject* dp, const(char)* key);
version(Python_2_7_Or_Later) {
    /// Availability: >= 2.7
    void _PyDict_DebugMallocStats(FILE* out_);
}

