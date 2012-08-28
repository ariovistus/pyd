module python2.codecs;

import python2.types;
import python2.object;

extern(C):
// Python-header-file: Include/codecs.h:

int PyCodec_Register(PyObject* search_function);
PyObject* _PyCodec_Lookup(const(char)* encoding);
PyObject* PyCodec_Encode(PyObject* object, const(char)* encoding, const(char)* errors);
PyObject* PyCodec_Decode(PyObject* object, const(char)* encoding, const(char)* errors);
PyObject* PyCodec_Encoder(const(char)* encoding);
PyObject* PyCodec_Decoder(const(char)* encoding);
PyObject* PyCodec_StreamReader(const(char)* encoding, PyObject* stream, const(char)* errors);
PyObject* PyCodec_StreamWriter(const(char)* encoding, PyObject* stream, const(char)* errors);

/////////////////////////////////////////////////////////////////////////////
// UNICODE ENCODING INTERFACE
/////////////////////////////////////////////////////////////////////////////

int PyCodec_RegisterError(const(char)* name, PyObject* error);
PyObject* PyCodec_LookupError(const(char)* name);
PyObject* PyCodec_StrictErrors(PyObject* exc);
PyObject* PyCodec_IgnoreErrors(PyObject* exc);
PyObject* PyCodec_ReplaceErrors(PyObject* exc);
PyObject* PyCodec_XMLCharRefReplaceErrors(PyObject* exc);
PyObject* PyCodec_BackslashReplaceErrors(PyObject* exc);


