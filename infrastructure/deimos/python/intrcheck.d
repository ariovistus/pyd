module deimos.python.intrcheck;

extern(C):
// Python-header-file: Include/intrcheck.h:

int PyOS_InterruptOccurred();
void PyOS_InitInterrupts();
void PyOS_AfterFork();


