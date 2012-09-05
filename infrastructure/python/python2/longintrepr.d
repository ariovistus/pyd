module python2.longobject;

import python2.types;
import python2.object;
import python2.unicodeobject;

extern(C):
// Python-header-file: Include/longintrepr.h:

struct PyLongObject {
	mixin PyObject_VAR_HEAD;
	ushort ob_digit[1];
}

PyLongObject* _PyLong_New(int);

/* Return a copy of src. */
PyObject* _PyLong_Copy(PyLongObject* src);
