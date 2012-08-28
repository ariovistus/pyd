module python2.timefuncs;

import std.c.time;

extern(C):
// Python-header-file: Include/timefuncs.h:

time_t _PyTime_DoubleToTimet(double x);



