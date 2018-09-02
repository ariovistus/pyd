// A minimal "hello world" Pyd module.
module hello;

import pyd.pyd;
import std.stdio;
import deimos.python.Python;

alias wrapperbase s_wrapperbase;
version(Python_3_7_Or_Later) {
alias PyCoreConfig _PyCoreConfig;
}
void add(string member)(ref int[string] dict) {
    dict[member] = mixin(member ~".offsetof");
}

int[string] offsets() {
	int[string] r;

	add!"PyByteArrayObject.ob_bytes"(r);
	add!"PyCellObject.ob_ref"(r);
	add!"PyMethodObject.im_weakreflist"(r);
	add!"PyCodeObject.co_lnotab"(r);
	add!"PyFutureFeatures.ff_lineno"(r);
	add!"PyComplexObject.cval"(r);
	add!"PyDateTime_Delta.microseconds"(r);
	add!"PyDateTime_Time.tzinfo"(r);
	add!"PyDateTime_Date.data"(r);
	add!"PyDateTime_DateTime.tzinfo"(r);
	add!"PyDateTime_CAPI.Date_FromTimestamp"(r);
	add!"PyGetSetDef.closure"(r);
	add!"s_wrapperbase.name_strobj"(r);
	add!"PyFloatObject.ob_fval"(r);
	add!"PyTryBlock.b_level"(r);
	add!"PyFrameObject.f_iblock"(r);
	add!"PyFunctionObject.func_module"(r);
	add!"PyGenObject.gi_weakreflist"(r);
	add!"PyListObject.allocated"(r);
	add!"PyLongObject.ob_digit"(r);
	add!"PyMethodDef.ml_doc"(r);
	add!"PyCFunctionObject.m_module"(r);
	add!"PyObject.ob_type"(r);
	add!"PyVarObject.ob_size"(r);
	add!"PyNumberMethods.nb_inplace_true_divide"(r);
	add!"PySequenceMethods.sq_inplace_repeat"(r);
	add!"PyMappingMethods.mp_ass_subscript"(r);
	add!"PyTypeObject.tp_richcompare"(r);
	add!"PyTypeObject.tp_alloc"(r);
	add!"PyTypeObject.tp_finalize"(r);
	add!"PyHeapTypeObject.as_buffer"(r);
	add!"PyThreadState.thread_id"(r);
	add!"PyInterpreterState.dlopenflags"(r);
	add!"PySetObject.weakreflist"(r);
	add!"PySliceObject.step"(r);
	add!"PyMemberDef.doc"(r);
	add!"PyStructSequence_Field.doc"(r);
	add!"PyStructSequence_Desc.n_in_sequence"(r);
	add!"PyTracebackObject.tb_lineno"(r);
	add!"PyWeakReference.wr_next"(r);
	add!"PyBufferProcs.bf_releasebuffer"(r);
version(Python_3_0_Or_Later) {
	add!"PyBytesObject.ob_shash"(r);
	add!"PyInstanceMethodObject.func"(r);
	add!"PyModuleDef.m_free"(r);
	add!"PyUnicodeObject.data"(r);
	add!"PyCompactUnicodeObject.wstr_length"(r);
	add!"PyASCIIObject.wstr"(r);
}else{
	add!"PyClassObject.cl_delattr"(r);
	add!"PyInstanceObject.in_weakreflist"(r);
	add!"PycStringIO_CAPI.OutputType"(r);
	add!"PyFileObject.weakreflist"(r);
	add!"PyIntObject.ob_ival"(r);
	add!"PyStringObject.ob_sstate"(r);
	add!"PyUnicodeObject.defenc"(r);
}

version(Python_2_5_Or_Later) {
	add!"PySyntaxErrorObject.print_file_and_line"(r);
	add!"PyUnicodeErrorObject.reason"(r);
	add!"PySystemExitObject.code"(r);
	add!"PyEnvironmentErrorObject.filename"(r);
 version(Windows) {
	add!"PyWindowsErrorObject.winerror"(r);
 }
}

version(Python_2_6_Or_Later) {
	add!"Py_buffer.internal"(r);
}

version(Python_2_7_Or_Later) {
	add!"PyMemoryViewObject.view"(r);
}

version(Python_3_2_Or_Later) {
}else version(Python_2_6_Or_Later) {
	add!"PyCObject.destructor"(r);
}

version(Python_3_4_Or_Later) {
	add!"PyDictObject.ma_values"(r);
}else {
	add!"PyDictObject.ma_lookup"(r);
	add!"PyDictEntry.me_value"(r);
}

version(Python_3_5_Or_Later)  {
	add!"PyAsyncMethods.am_anext"(r);
}

version(Python_3_6_Or_Later) {
	add!"PyCodeObject.co_extra"(r);
	add!"PyThreadState.async_gen_finalizer"(r);
	add!"PyInterpreterState.eval_frame"(r);
}

version(Python_3_7_Or_Later) {
	add!"PyContext.ctx_entered"(r);
	add!"PyContextVar.var_hash"(r);
	add!"PyContextToken.tok_used"(r);
	add!"PyCoreConfig.base_exec_prefix"(r);
	add!"PyThreadState.id"(r);
	add!"PyInterpreterState.tstate_next_unique_id"(r);
}

	return r;
}

extern(C) void PydMain() {
    def!(offsets)();
    module_init();
}
