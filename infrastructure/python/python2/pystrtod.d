module python2.pystrtod;

extern(C):
// Python-header-file: Include/pystrtod.h:

double PyOS_ascii_strtod(const(char)* str, char** ptr);
double PyOS_ascii_atof(const(char)* str);
char* PyOS_ascii_formatd(char* buffer, size_t buf_len, const(char)* format, double d);

