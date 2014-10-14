/**
  Mirror _longintrepr.h
  */
module deimos.python.longintrepr;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.unicodeobject;

extern(C):
// Python-header-file: Include/longintrepr.h:

/** Long integer representation.
   The absolute value of a number is equal to
   	SUM(for i=0 through abs(ob_size)-1) ob_digit[i] * 2**(SHIFT*i)
   Negative numbers are represented with ob_size < 0;
   zero is represented by ob_size == 0.
   In a normalized number, ob_digit[abs(ob_size)-1] (the most significant
   digit) is never zero.  Also, in all cases, for all valid i,
   	0 <= ob_digit[i] <= MASK.
   The allocation function takes care of allocating extra memory
   so that ob_digit[0] ... ob_digit[abs(ob_size)-1] are actually available.

   CAUTION:  Generic code manipulating subtypes of PyVarObject has to
   aware that longs abuse  ob_size's sign bit.
*/
struct PyLongObject {
	mixin PyObject_VAR_HEAD;
	ushort[1] ob_digit;
}

/// _
PyLongObject* _PyLong_New(int);

/** Return a copy of src. */
PyObject* _PyLong_Copy(PyLongObject* src);
