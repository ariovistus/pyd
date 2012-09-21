/**
  Mirror _intrcheck.h
  */
module deimos.python.intrcheck;

extern(C):
// Python-header-file: Include/intrcheck.h:

/// _
int PyOS_InterruptOccurred();
/// _
void PyOS_InitInterrupts();
/// _
void PyOS_AfterFork();


