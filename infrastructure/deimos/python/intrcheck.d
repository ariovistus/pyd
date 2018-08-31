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

version(Python_3_7_Or_Later) {
    void PyOS_BeforeFork();
    void PyOS_AfterFork_Parent();
    void PyOS_AfterFork_Child();
}
/// _
void PyOS_AfterFork();


