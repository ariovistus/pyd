/**
  Mirror _pgenheaders.h
  */
module deimos.python.pgenheaders;

extern(C):
// Python-header-file: Include/pgenheaders.h:

/// _
void PySys_WriteStdout(const(char)* format, ...);
/// _
void PySys_WriteStderr(const(char)* format, ...);
