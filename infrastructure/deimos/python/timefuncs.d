/**
  Mirror _timefuncs.h
  */
module deimos.python.timefuncs;

import std.c.time;

extern(C):
// Python-header-file: Include/timefuncs.h:

/// _
time_t _PyTime_DoubleToTimet(double x);



