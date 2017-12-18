/**
  Mirror _pyport.h
  */
module deimos.python.pyport;

import core.stdc.config;

/* D long is always 64 bits, but when the Python/C API mentions long, it is of
 * course referring to the C type long, the size of which is 32 bits on both
 * X86 and X86_64 under Windows, but 32 bits on X86 and 64 bits on X86_64 under
 * most other operating systems. */

/// _
alias long C_longlong;
/// _
alias ulong C_ulonglong;

alias core.stdc.config.c_long C_long;
alias core.stdc.config.c_ulong C_ulong;

/*
 * Py_ssize_t is defined as a signed type which is 8 bytes on X86_64 and 4
 * bytes on X86.
 */
version(Python_2_5_Or_Later){
    version (X86_64) {
        /// _
        alias long Py_ssize_t;
    } else {
        /// _
        alias int Py_ssize_t;
    }
    version(Python_3_2_Or_Later) {
        /// Availability: >= 3.2
        /// (Py_hash_t invariably replaces C_long, so we always define it for
        /// convenience)
        alias Py_ssize_t Py_hash_t;
        /// Availability: >= 3.2
        alias size_t Py_uhash_t;
    }else{
        alias C_long Py_hash_t;
    }
}else {
    /*
     * Seems Py_ssize_t didn't exist in 2.4, and int was everywhere it is now.
     */
    /// _
    alias int Py_ssize_t;
    /*
     * Seems Py_hash_t didn't exist in 2.4, and C_long was everywhere it is now.
     */
    /// _
    alias C_long Py_hash_t;
}

version(linux) version(DigitalMars) version = dmd_linux;
version(OSX) version(DigitalMars) version = dmd_osx;
template PyAPI_DATA(string decl) {

    version(dmd_linux) {
        // has to be special

        // todo: why does ldc/linux not work this way?
        //  --export-dynamic seems not to change anything
        // export causes dmd to prepend symbols with _imp__, so no use.
        // extern is not necessary for single-command builds
        //               necessary for traditional per-file builds.
        enum PyAPI_DATA = (q{
            extern(C)
            extern
            __gshared
        } ~ decl ~ ";");
    } else version(dmd_osx) {
        enum PyAPI_DATA = (q{
            extern(C)
            extern
            __gshared
        } ~ decl ~ ";");
    } else {
        enum PyAPI_DATA = (q{
            extern(C)
            extern
            export
            __gshared
        } ~ decl ~ ";");
    }
}
