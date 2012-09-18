module deimos.python.pyport;

import deimos.python.fiddle;

/* D long is always 64 bits, but when the Python/C API mentions long, it is of
 * course referring to the C type long, the size of which is 32 bits on both
 * X86 and X86_64 under Windows, but 32 bits on X86 and 64 bits on X86_64 under
 * most other operating systems. */

alias long C_longlong;
alias ulong C_ulonglong;

version(Windows) {
  alias int C_long;
  alias uint C_ulong;
} else {
  version (X86) {
    alias int C_long;
    alias uint C_ulong;
  } else {
    alias long C_long;
    alias ulong C_ulong;
  }
}


/*
 * Py_ssize_t is defined as a signed type which is 8 bytes on X86_64 and 4
 * bytes on X86.
 */
version(Python_2_5_Or_Later){
    version (X86_64) {
        alias long Py_ssize_t;
    } else {
        alias int Py_ssize_t;
    }
    version(Python_3_2_Or_Later) {
        alias Py_ssize_t Py_hash_t;
        alias size_t Py_uhash_t;
    }
}else {
    /*
     * Seems Py_ssize_t didn't exist in 2.4, and int was everywhere it is now.
     */
    alias int Py_ssize_t;
}

version(Python_2_5_Or_Later){
    alias const(char)	Char1;
}else{
    alias char	Char1;
}
