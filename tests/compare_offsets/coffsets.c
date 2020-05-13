#include <Python.h>
#include <datetime.h>
#include <frameobject.h>
#include <structmember.h>
#include <structseq.h>
#include <pystate.h>
#include <longintrepr.h>
#include <stdio.h>

#if PY_MAJOR_VERSION >= 3 && PY_MINOR_VERSION == 7
	typedef _PyCoreConfig PyCoreConfig;
#endif
typedef struct wrapperbase s_wrapperbase;
typedef struct _longobject PyLongObject;

#define RRadd(tipo, member) { \
	tipo t; \
	PyDict_SetItem(dict, PyUnicode_FromString(#tipo "." #member), PyLong_FromUnsignedLong((size_t)(&t.member) - (size_t)&t));  \
}

PyObject *offsets(PyObject *ignoredparam1, PyObject *ignoredparam2) {
	// vim helper: %s/^\(\s*\)add!"\([^.]\+\)\.\([^"]\+\)".*/\1RRadd(\2, \3);/g
	PyObject *dict = PyDict_New();

	RRadd(PyByteArrayObject, ob_bytes);
	RRadd(PyCellObject, ob_ref);
	RRadd(PyMethodObject, im_weakreflist);
	RRadd(PyCodeObject, co_lnotab);
	RRadd(PyFutureFeatures, ff_lineno);
	RRadd(PyComplexObject, cval);
	RRadd(PyDateTime_Delta, microseconds);
	RRadd(PyDateTime_Time, tzinfo);
	RRadd(PyDateTime_Date, data);
	RRadd(PyDateTime_DateTime, tzinfo);
	RRadd(PyDateTime_CAPI, Date_FromTimestamp);
	RRadd(PyGetSetDef, closure);
	RRadd(s_wrapperbase, name_strobj);
	RRadd(PyFloatObject, ob_fval);
	RRadd(PyTryBlock, b_level);
	RRadd(PyFrameObject, f_iblock);
	RRadd(PyFunctionObject, func_module);
	RRadd(PyGenObject, gi_weakreflist);
	RRadd(PyListObject, allocated);
	RRadd(PyLongObject, ob_digit);
	RRadd(PyMethodDef, ml_doc);
	RRadd(PyCFunctionObject, m_module);
	RRadd(PyObject, ob_type);
	RRadd(PyVarObject, ob_size);
	RRadd(PyNumberMethods, nb_inplace_true_divide);
	RRadd(PySequenceMethods, sq_inplace_repeat);
	RRadd(PyMappingMethods, mp_ass_subscript);
	RRadd(PyTypeObject, tp_richcompare);
	RRadd(PyTypeObject, tp_alloc);
	RRadd(PyHeapTypeObject, as_buffer);
	RRadd(PyThreadState, thread_id);
#if PY_MAJOR_VERSION != 3 || PY_MINOR_VERSION <= 7
	RRadd(PyInterpreterState, dlopenflags);
#endif
	RRadd(PySetObject, weakreflist);
	RRadd(PySliceObject, step);
	RRadd(PyMemberDef, doc);
	RRadd(PyStructSequence_Field, doc);
	RRadd(PyStructSequence_Desc, n_in_sequence);
	RRadd(PyTracebackObject, tb_lineno);
	RRadd(PyWeakReference, wr_next);
	RRadd(PyBufferProcs, bf_releasebuffer);
#if PY_MAJOR_VERSION >= 3
	RRadd(PyBytesObject, ob_shash);
	RRadd(PyInstanceMethodObject, func);
	RRadd(PyModuleDef, m_free);
	RRadd(PyUnicodeObject, data);
	RRadd(PyCompactUnicodeObject, wstr_length);
	RRadd(PyASCIIObject, wstr);
	RRadd(PyTypeObject, tp_finalize);
#else
	RRadd(PyClassObject, cl_delattr);
	RRadd(PyInstanceObject, in_weakreflist);
	RRadd(PyFileObject, weakreflist);
	RRadd(PyIntObject, ob_ival);
	RRadd(PyStringObject, ob_sstate);
	RRadd(PyUnicodeObject, defenc);
#endif

#if PY_MAJOR_VERSION > 2 || PY_MINOR_VERSION >= 5
	RRadd(PySyntaxErrorObject, print_file_and_line);
	RRadd(PyUnicodeErrorObject, reason);
	RRadd(PySystemExitObject, code);
	RRadd(PyEnvironmentErrorObject, filename);
#ifdef MS_WINDOWS
	RRadd(PyWindowsErrorObject, winerror);
#endif
#endif

#if PY_MAJOR_VERSION > 2 || PY_MINOR_VERSION >= 6
	RRadd(Py_buffer, internal);
#endif

#if PY_MAJOR_VERSION > 2 || PY_MINOR_VERSION >= 7
	RRadd(PyMemoryViewObject, view);
#endif

#if PY_MAJOR_VERSION < 3 || PY_MINOR_VERSION < 2
	RRadd(PyCObject, destructor);
#endif

#if PY_MAJOR_VERSION >= 3 && PY_MINOR_VERSION >= 4
	RRadd(PyDictObject, ma_values);
#else
	RRadd(PyDictObject, ma_lookup);
	RRadd(PyDictEntry, me_value);
#endif

#if PY_MAJOR_VERSION >= 3 && PY_MINOR_VERSION >= 5
	RRadd(PyAsyncMethods, am_anext);
#endif

#if PY_MAJOR_VERSION >= 3 && PY_MINOR_VERSION >= 6
	RRadd(PyCodeObject, co_extra);
	RRadd(PyThreadState, async_gen_finalizer);
#if PY_MINOR_VERSION < 8
	RRadd(PyInterpreterState, eval_frame);
#endif
#endif

#if PY_MAJOR_VERSION >= 3 && PY_MINOR_VERSION == 7
	RRadd(PyCoreConfig, base_exec_prefix);
	RRadd(PyThreadState, id);
	RRadd(PyInterpreterState, tstate_next_unique_id);
#endif


	return dict;
}

static PyMethodDef x_methods[] = {
    {"offsets", &offsets, METH_VARARGS, "tacos tacos"},
    {NULL} /*sentinal*/
};

#ifndef PyMODINIT_FUNC
#define PyMODINIT_FUNC void
#endif

#if PY_MAJOR_VERSION >= 3
static struct PyModuleDef moduledef = {
    PyModuleDef_HEAD_INIT,
    "coffsets",
    NULL,
    -1,
    x_methods,
    NULL,
    NULL,
    NULL,
    NULL
};
PyObject *PyInit_coffsets(void)
#else
    PyMODINIT_FUNC
initcoffsets(void)
#endif
{
    PyObject* m;

#if PY_MAJOR_VERSION >= 3
    m = PyModule_Create(&moduledef);
#else

    // this is important!
    m = Py_InitModule3("coffsets", x_methods, "Hi ho, pipsissiwa is slow");
#endif

#if PY_MAJOR_VERSION >= 3
    return m;
#endif
}
