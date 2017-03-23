/**
  Mirror _codecs.h

  [which was]

Written by Marc-Andre Lemburg (mal@lemburg.com).

Copyright (c) Corporation for National Research Initiatives.

   Python Codec Registry and support functions
  */
module deimos.python.codecs;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/codecs.h:

/** Register a new codec search function.

   As side effect, this tries to load the encodings package, if not
   yet done, to make sure that it is always first in the list of
   search functions.

   The search_function's refcount is incremented by this function. */
int PyCodec_Register(PyObject* search_function);
/** Codec register lookup API.

   Looks up the given encoding and returns a CodecInfo object with
   function attributes which implement the different aspects of
   processing the encoding.

   The encoding string is looked up converted to all lower-case
   characters. This makes encodings looked up through this mechanism
   effectively case-insensitive.

   If no codec is found, a KeyError is set and NULL returned.

   As side effect, this tries to load the encodings package, if not
   yet done. This is part of the lazy load strategy for the encodings
   package.

 */
PyObject* _PyCodec_Lookup(const(char)* encoding);
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    int PyCodec_KnownEncoding(
            const(char)* encoding
            );
}
/** Generic codec based _encoding API.

   object is passed through the encoder function found for the given
   encoding using the error handling method defined by errors. errors
   may be NULL to use the default method defined for the codec.

   Raises a LookupError in case no encoder can be found.

 */
PyObject* PyCodec_Encode(PyObject* object, const(char)* encoding, const(char)* errors);
/** Generic codec based decoding API.

   object is passed through the decoder function found for the given
   encoding using the error handling method defined by errors. errors
   may be NULL to use the default method defined for the codec.

   Raises a LookupError in case no encoder can be found.

 */
PyObject* PyCodec_Decode(PyObject* object, const(char)* encoding, const(char)* errors);
/** Get an encoder function for the given encoding. */
PyObject* PyCodec_Encoder(const(char)* encoding);
/** Get a decoder function for the given encoding. */
PyObject* PyCodec_Decoder(const(char)* encoding);
version(Python_2_5_Or_Later) {
    /** Get a IncrementalEncoder object for the given encoding. */
    /// Availability: >= 2.5

    PyObject* PyCodec_IncrementalEncoder(
            const(char)* encoding,
            const(char)* errors
            );

    /** Get a IncrementalDecoder object function for the given encoding. */
    /// Availability: >= 2.5

    PyObject* PyCodec_IncrementalDecoder(
            const(char)* encoding,
            const(char)* errors
            );
}
/** Get a StreamReader factory function for the given encoding. */
PyObject* PyCodec_StreamReader(
        const(char)* encoding,
        PyObject* stream,
        const(char)* errors);
/** Get a StreamWriter factory function for the given encoding. */
PyObject* PyCodec_StreamWriter(const(char)* encoding, PyObject* stream, const(char)* errors);

//-//////////////////////////////////////////////////////////////////////////
// UNICODE ENCODING INTERFACE
//-//////////////////////////////////////////////////////////////////////////

/** Register the _error handling callback function error under the given
   name. This function will be called by the codec when it encounters
   unencodable characters/undecodable bytes and doesn't know the
   callback _name, when name is specified as the error parameter
   in the call to the encode/decode function.
   Return 0 on success, -1 on _error */
int PyCodec_RegisterError(const(char)* name, PyObject* error);
/** Lookup the error handling callback function registered under the given
   name. As a special case NULL can be passed, in which case
   the error handling callback for "strict" will be returned. */
PyObject* PyCodec_LookupError(const(char)* name);
/** raise exc as an exception */
PyObject* PyCodec_StrictErrors(PyObject* exc);
/** ignore the unicode error, skipping the faulty input */
PyObject* PyCodec_IgnoreErrors(PyObject* exc);
/** replace the unicode encode error with ? or U+FFFD */
PyObject* PyCodec_ReplaceErrors(PyObject* exc);
/** replace the unicode encode error with XML character references */
PyObject* PyCodec_XMLCharRefReplaceErrors(PyObject* exc);
/** replace the unicode encode error with backslash escapes (\x, \u and \U) */
PyObject* PyCodec_BackslashReplaceErrors(PyObject* exc);

version(Python_3_5_Or_Later) {
    /** replace the unicode encode error with backslash escapes (\N, \x, \u and \U) */
    PyObject* PyCodec_NameReplaceErrors(PyObject* exc);
}

