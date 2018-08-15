/**
  Mirror _pyatomic.h

  Note this is python 3 only
  (and very probably doesn't work period)
  */
// todo: 3.7 update
module deimos.python.pyatomic;

/* This is modeled after the atomics interface from C1x, according to
 * the draft at
 * http://www.open-std.org/JTC1/SC22/wg14/www/docs/n1425.pdf.
 * Operations and types are named the same except with a _Py_ prefix
 * and have the same semantics.
 *
 * Beware, the implementations here are deep magic.
 */

version(Python_3_0_Or_Later) {
    extern(C):
    enum _Py_memory_order {
        _Py_memory_order_relaxed,
        _Py_memory_order_acquire,
        _Py_memory_order_release,
        _Py_memory_order_acq_rel,
        _Py_memory_order_seq_cst
    }

    struct _Py_atomic_address {
        void* _value;
    }

    struct _Py_atomic_int {
        int _value;
    }

    /* Fall back to other compilers and processors by assuming that simple
       volatile accesses are atomic.  This is false, so people should port
       this. */
    auto _Py_atomic_signal_fence()(_Py_memory_order order) {
        (cast(void)0);
    }
    auto _Py_atomic_thread_fence()(_Py_memory_order order) {
        (cast(void)0);
    }
    void _Py_atomic_store_explicit(ATOMIC_VAL, NEW_VAL)(ATOMIC_VAL val,
            NEW_VAL val2, _Py_memory_order order) {
        val._value = val2;
    }
    auto _Py_atomic_load_explicit(ATOMIC_VAL)(ATOMIC_VAL val,
            _Py_memory_order order) {
        return val._value;
    }

    /* Standardized shortcuts. */
    void _Py_atomic_store(ATOMIC_VAL, NEW_VAL)(ATOMIC_VAL val, NEW_VAL val2) {
        _Py_atomic_store_explicit(val, val2,
                _Py_memory_order._Py_memory_order_seq_cst);
    }
    auto _Py_atomic_load(ATOMIC_VAL)(ATOMIC_VAL val) {
        return _Py_atomic_load_explicit(val,
                _Py_memory_order._Py_memory_order_seq_cst);
    }

    /* Python-local extensions */

    void _Py_atomic_store_relaxed(ATOMIC_VAL, NEW_VAL)(ATOMIC_VAL val,
            NEW_VAL val2) {
        _Py_atomic_store_explicit(val, val2, _Py_memory_order._Py_memory_order_relaxed);
    }
    auto _Py_atomic_load_relaxed(ATOMIC_VAL)(ATOMIC_VAL val) {
        return _Py_atomic_load_explicit(val, _Py_memory_order._Py_memory_order_relaxed);
    }
}
