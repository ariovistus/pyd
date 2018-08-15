/**
  Mirror _odictobject.h
  */
module deimos.python.odictobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.dictobject;


version(Python_3_5_Or_Later) {
    mixin(PyAPI_DATA!"PyTypeObject PyODict_Type");
    mixin(PyAPI_DATA!"PyTypeObject PyODictIter_Type");
    mixin(PyAPI_DATA!"PyTypeObject PyODictKeys_Type");
    mixin(PyAPI_DATA!"PyTypeObject PyODictItems_Type");
    mixin(PyAPI_DATA!"PyTypeObject PyODictValues_Type");

    // D translation of C macro:
    /// _
    int PyODict_Check()(PyObject* op) {
        return PyObject_TypeCheck(op, &PyODict_Type);
    }

    // D translation of C macro:
    /// _
    int PyODict_CheckExact()(PyObject* op) {
            return Py_TYPE(op) == &PyODict_Type;
    }

    // D translation of C macro:
    /// _
    int PyODict_SIZE()(PyObject* op) {
        version(Python_3_7_Or_Later) {
            return PyDict_GET_SIZE(op);
        }else{
            return (cast(PyDictObject*)op).ma_used;
        }
    }

    // D translation of C macro:
    /// _
    bool PyODict_HasKey()(PyObject* od, char* key) {
        return PyMapping_HasKey(od, key);
    }

    /// _
    PyObject* PyODict_New();

    /// _
    int PyODict_SetItem(PyObject* od, PyObject* key, PyObject* item);

    /// _
    int PyODict_DelItem(PyObject* od, PyObject* key);

    /// _
    Borrowed!PyObject* PyODict_GetItem()(PyObject* od, PyObject* key) {
        return PyDict_GetItem(od, key);
    }

    /// _
    Borrowed!PyObject* PyDict_GetItemWithError()(PyObject* od, PyObject* key) {
        return PyDict_GetItemWithError(od, key);
    }

    /// _
    int PyODict_Contains()(PyObject* od, PyObject* key) {
        return PyDict_Contains(od, key);
    }

    /// _
    Py_ssize_t PyODict_Size()(PyObject* od) {
        return PyDict_Size(od);
    }

    /// _
    Borrowed!PyObject* PyODict_GetItemString()(PyObject* od, const(char)* key) {
        return PyDict_GetItemString(od, key);
    }
}
