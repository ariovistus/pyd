module deimos.python.longobject;

import deimos.python.pyport;
import deimos.python.object;
import deimos.python.unicodeobject;

extern(C):
// Python-header-file: Include/longintrepr.h:

struct PyLongObject {
	mixin PyObject_VAR_HEAD;
	ushort ob_digit[1];
}

PyLongObject* _PyLong_New(int);

/* Return a copy of src. */
PyObject* _PyLong_Copy(PyLongObject* src);
