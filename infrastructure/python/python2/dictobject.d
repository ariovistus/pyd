module python2.dictobject;

import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/dictobject.h:

enum int PyDict_MINSIZE = 8;

struct PyDictEntry {
    version(Python_2_5_Or_Later){
        Py_ssize_t me_hash;
    }else{
        C_long me_hash;
    }
    PyObject* me_key;
    PyObject* me_value;
}

struct _dictobject {
    mixin PyObject_HEAD;

    Py_ssize_t ma_fill;
    Py_ssize_t ma_used;
    Py_ssize_t ma_mask;
    PyDictEntry *ma_table;
    PyDictEntry* function(PyDictObject *mp, PyObject* key, C_long hash) ma_lookup;
    PyDictEntry ma_smalltable[PyDict_MINSIZE];
}
alias _dictobject PyDictObject;

__gshared PyTypeObject PyDict_Type;
version(Python_2_7_Or_Later) {
    __gshared PyTypeObject PyDictIterKey_Type;
    __gshared PyTypeObject PyDictIterValue_Type;
    __gshared PyTypeObject PyDictIterItem_Type;
    __gshared PyTypeObject PyDictKeys_Type;
    __gshared PyTypeObject PyDictItems_Type;
    __gshared PyTypeObject PyDictValues_Type;
}

// D translation of C macro:
int PyDict_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, &PyDict_Type);
}
// D translation of C macro:
int PyDict_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == &PyDict_Type;
}

version(Python_2_7_Or_Later) {
    int PyDictKeys_Check()(PyObject* op) {
        return Py_TYPE(op) == &PyDictKeys_Type;
    }
    int PyDictItems_Check()(PyObject* op) {
        return Py_TYPE(op) == &PyDictItems_Type;
    }
    int PyDictValues_Check()(PyObject* op) {
        return Py_TYPE(op) == &PyDictValues_Type;
    }
    int PyDictViewSet_Check()(PyObject* op) {
        return PyDictKeys_Check(op) || PyDictItems_Check(op);
    }
}

PyObject* PyDict_New();
PyObject_BorrowedRef* PyDict_GetItem(PyObject* mp, PyObject* key);
int PyDict_SetItem(PyObject* mp, PyObject* key, PyObject* item);
int PyDict_DelItem(PyObject* mp, PyObject* key);
void PyDict_Clear(PyObject* mp);
int PyDict_Next(PyObject* mp, Py_ssize_t* pos, PyObject_BorrowedRef **key, PyObject_BorrowedRef **value);
PyObject* PyDict_Keys(PyObject* mp);
PyObject* PyDict_Values(PyObject* mp);
PyObject* PyDict_Items(PyObject* mp);
Py_ssize_t PyDict_Size(PyObject* mp);
PyObject* PyDict_Copy(PyObject* mp);
int PyDict_Contains(PyObject* mp, PyObject* key);

int PyDict_Update(PyObject* mp, PyObject* other);
int PyDict_Merge(PyObject* mp, PyObject* other, int override_);
int PyDict_MergeFromSeq2(PyObject* d, PyObject* seq2, int override_);

PyObject_BorrowedRef* PyDict_GetItemString(PyObject* dp, const(char)* key);
int PyDict_SetItemString(PyObject* dp, const(char)* key, PyObject* item);
int PyDict_DelItemString(PyObject* dp, const(char)* key);


