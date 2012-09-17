module deimos.python.pystrtod;

import deimos.python.object;

extern(C):
// Python-header-file: Include/pystrtod.h:

version(Python_3_2_Or_Later) {
}else{
    double PyOS_ascii_strtod(const(char)* str, char** ptr);
    double PyOS_ascii_atof(const(char)* str);
    char* PyOS_ascii_formatd(
            char* buffer, 
            size_t buf_len, 
            const(char)* format, 
            double d);
}

version(Python_2_7_Or_Later) {
    double PyOS_string_to_double(
            const(char)* str,
            char** endptr,
            PyObject* overflow_exception);

    /* The caller is responsible for calling PyMem_Free to free the buffer
       that's is returned. */
    char* PyOS_double_to_string(
            double val,
            char format_code,
            int precision,
            int flags,
            int* type);

    double _Py_parse_inf_or_nan(const(char)* p, char** endptr);
}

