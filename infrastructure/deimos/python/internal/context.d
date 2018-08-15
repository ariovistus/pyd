/**
  Mirror internal/context.h

  */

module deimos.python.internal.context;

import deimos.python.pyport;
import deimos.python.internal.hamt;
import deimos.python.object;

extern(C): version(Python_3_7_Or_Later):
    struct PyContext {
        mixin PyObject_HEAD!();
        PyContext* ctx_prev;
        PyHamtObject* ctx_vars;
        PyObject* ctx_weakreflist;
        int ctx_entered;
    }

    struct PyContextVar {
        mixin PyObject_HEAD!();
        PyObject* var_name;
        PyObject* var_default;
        PyObject* var_cached;
        ulong var_cached_tsid;
        ulong var_cached_tsver;
        Py_hash_t var_hash;
    }

    struct PyContextToken {
        mixin PyObject_HEAD!();
        PyContext* tok_ctx;
        PyContextVar* tok_var;
        PyObject* tok_oldval;
        int tok_used;
    }
