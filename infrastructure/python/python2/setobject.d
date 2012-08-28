module python2.setobject;

import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/setobject.h:

version(Python_2_5_Or_Later){
    enum PySet_MINSIZE = 8;

    struct setentry {
        C_long hash;
        PyObject* key;
    }
}

struct PySetObject {
    mixin PyObject_HEAD;

    version(Python_2_5_Or_Later){
        Py_ssize_t fill;
        Py_ssize_t used;

        Py_ssize_t mask;

        setentry *table;
        setentry* function(PySetObject *so, PyObject* key, C_long hash) lookup;
        setentry smalltable[PySet_MINSIZE];
    }else{
        PyObject* data;
    }

    C_long hash;
    PyObject* weakreflist;
}

__gshared PyTypeObject PySet_Type;
__gshared PyTypeObject PyFrozenSet_Type;

// D translations of C macros:
int PyFrozenSet_CheckExact()(PyObject* ob) {
    return Py_TYPE(ob) == &PyFrozenSet_Type;
}
int PyAnySet_CheckExact()(PyObject* ob) {
    return Py_TYPE(ob) == &PySet_Type || Py_TYPE(ob) == &PyFrozenSet_Type;
}
int PyAnySet_Check()(PyObject* ob) {
    return (
         Py_TYPE(ob) == &PySet_Type
      || Py_TYPE(ob) == &PyFrozenSet_Type
      || PyType_IsSubtype(Py_TYPE(ob), &PySet_Type)
      || PyType_IsSubtype(Py_TYPE(ob), &PyFrozenSet_Type)
    );
}
version(Python_2_6_Or_Later){
    bool PySet_Check()(PyObject* ob) {
        return (Py_TYPE(ob) == &PySet_Type || 
                PyType_IsSubtype(Py_TYPE(ob), &PySet_Type));
    }
    bool PyFrozenSet_Check()(PyObject* ob) {
        return (Py_TYPE(ob) == &PyFrozenSet_Type || 
                PyType_IsSubtype(Py_TYPE(ob), &PyFrozenSet_Type));
    }
}

version(Python_2_5_Or_Later){
    PyObject* PySet_New(PyObject*);
    PyObject* PyFrozenSet_New(PyObject*);
    Py_ssize_t PySet_Size(PyObject* anyset);
    Py_ssize_t PySet_GET_SIZE()(PyObject* so) {
        return (cast(PySetObject*)so).used;
    }
    int PySet_Clear(PyObject* set);
    int PySet_Contains(PyObject* anyset, PyObject* key);
    int PySet_Discard(PyObject* set, PyObject* key);
    int PySet_Add(PyObject* set, PyObject* key);
    int _PySet_Next(PyObject* set, Py_ssize_t *pos, PyObject** entry);
    PyObject* PySet_Pop(PyObject* set);
    int _PySet_Update(PyObject* set, PyObject* iterable);
}

