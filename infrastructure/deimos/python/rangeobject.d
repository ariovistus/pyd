/**
  Mirror _rangeobject.h

  This is about the type 'xrange', not the built-in function range(), which
  returns regular lists.

  A range object represents an integer range.  This is an immutable object;
  a range cannot change its value after creation.

  Range objects behave like the corresponding tuple objects except that
  they are represented by a start, stop, and step datamembers.
 */
module deimos.python.rangeobject;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/rangeobject.h:

/// _
mixin(PyAPI_DATA!"PyTypeObject PyRange_Type");
/// _
mixin(PyAPI_DATA!"PyTypeObject PyRangeIter_Type");
/// _
mixin(PyAPI_DATA!"PyTypeObject PyLongRangeIter_Type");

// D translation of C macro:
/// _
int PyRange_Check()(PyObject *op) {
    return Py_TYPE(op) == &PyRange_Type;
}

version(Python_2_5_Or_Later){
    // Removed in 2.5
}else{
    /// Availability: 2.4
    PyObject* PyRange_New(C_long, C_long, C_long, int);
}


