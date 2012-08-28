module python2.pgenheaders;

extern(C):
// Python-header-file: Include/pgenheaders.h:

void PySys_WriteStdout(const(char)* format, ...);
void PySys_WriteStderr(const(char)* format, ...);
