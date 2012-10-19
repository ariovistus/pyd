/**
  Mirror _enumobject.h
  */
module deimos.python.enumobject;

import deimos.python.pyport;
import deimos.python.object;

/// _
mixin(PyAPI_DATA!"PyTypeObject PyEnum_Type");
/// _
mixin(PyAPI_DATA!"PyTypeObject PyReversed_Type");
