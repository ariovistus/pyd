module deimos.python.datetime;
import util.conv;
import deimos.python.object;
import deimos.python.pyport;

extern(C):
// Python-header-file: Include/datetime.h:

enum _PyDateTime_DATE_DATASIZE = 4;
enum _PyDateTime_TIME_DATASIZE = 6;
enum _PyDateTime_DATETIME_DATASIZE = 10;

struct PyDateTime_Delta {
    mixin PyObject_HEAD;

    version(Python_3_0_Or_Later) {
        Py_hash_t hashcode;
    }else {
        C_long hashcode;
    }
    int days;
    int seconds;
    int microseconds;
}

struct PyDateTime_TZInfo {
    mixin PyObject_HEAD;
}

template _PyTZINFO_HEAD() {
    mixin PyObject_HEAD;
    version(Python_3_0_Or_Later) {
        Py_hash_t hashcode;
    }else {
        C_long hashcode;
    }
    ubyte hastzinfo;
}

struct _PyDateTime_BaseTZInfo {
    mixin _PyTZINFO_HEAD;
}

template _PyDateTime_TIMEHEAD() {
    mixin _PyTZINFO_HEAD;
    ubyte data[_PyDateTime_TIME_DATASIZE];
}

struct _PyDateTime_BaseTime {
    mixin _PyDateTime_TIMEHEAD;
}

struct PyDateTime_Time {
    mixin _PyDateTime_TIMEHEAD;
    PyObject* tzinfo;
}

struct PyDateTime_Date {
    mixin _PyTZINFO_HEAD;
    ubyte data[_PyDateTime_DATE_DATASIZE];
}

template _PyDateTime_DATETIMEHEAD() {
    mixin _PyTZINFO_HEAD;
    ubyte data[_PyDateTime_DATETIME_DATASIZE];
}

struct _PyDateTime_BaseDateTime {
    mixin _PyDateTime_DATETIMEHEAD;
}

struct PyDateTime_DateTime {
    mixin _PyDateTime_DATETIMEHEAD;
    PyObject* tzinfo;
}

// D translations of C macros:
int PyDateTime_GET_YEAR()(PyObject* o) {
    PyDateTime_Date *ot = cast(PyDateTime_Date *) o;
    return (ot.data[0] << 8) | ot.data[1];
}
int PyDateTime_GET_MONTH()(PyObject* o) {
    PyDateTime_Date *ot = cast(PyDateTime_Date *) o;
    return ot.data[2];
}
int PyDateTime_GET_DAY()(PyObject* o) {
    PyDateTime_Date *ot = cast(PyDateTime_Date *) o;
    return ot.data[3];
}

int PyDateTime_DATE_GET_HOUR()(PyObject* o) {
    PyDateTime_DateTime *ot = cast(PyDateTime_DateTime *) o;
    return ot.data[4];
}
int PyDateTime_DATE_GET_MINUTE()(PyObject* o) {
    PyDateTime_DateTime *ot = cast(PyDateTime_DateTime *) o;
    return ot.data[5];
}
int PyDateTime_DATE_GET_SECOND()(PyObject* o) {
    PyDateTime_DateTime *ot = cast(PyDateTime_DateTime *) o;
    return ot.data[6];
}
int PyDateTime_DATE_GET_MICROSECOND()(PyObject* o) {
    PyDateTime_DateTime *ot = cast(PyDateTime_DateTime *) o;
    return (ot.data[7] << 16) | (ot.data[8] << 8) | ot.data[9];
}

int PyDateTime_TIME_GET_HOUR()(PyObject* o) {
    PyDateTime_Time *ot = cast(PyDateTime_Time *) o;
    return ot.data[0];
}
int PyDateTime_TIME_GET_MINUTE()(PyObject* o) {
    PyDateTime_Time *ot = cast(PyDateTime_Time *) o;
    return ot.data[1];
}
int PyDateTime_TIME_GET_SECOND()(PyObject* o) {
    PyDateTime_Time *ot = cast(PyDateTime_Time *) o;
    return ot.data[2];
}
int PyDateTime_TIME_GET_MICROSECOND()(PyObject* o) {
    PyDateTime_Time *ot = cast(PyDateTime_Time *) o;
    return (ot.data[3] << 16) | (ot.data[4] << 8) | ot.data[5];
}

struct PyDateTime_CAPI {
    PyTypeObject* DateType;
    PyTypeObject* DateTimeType;
    PyTypeObject* TimeType;
    PyTypeObject* DeltaType;
    PyTypeObject* TZInfoType;

    PyObject* function(int, int, int, PyTypeObject*) Date_FromDate;
    PyObject* function(int, int, int, int, int, int, int,
            PyObject*, PyTypeObject*) DateTime_FromDateAndTime;
    PyObject* function(int, int, int, int, PyObject*, PyTypeObject*) Time_FromTime;
    PyObject* function(int, int, int, int, PyTypeObject*) Delta_FromDelta;

    PyObject* function(PyObject*, PyObject*, PyObject*) DateTime_FromTimestamp;
    PyObject* function(PyObject*, PyObject*) Date_FromTimestamp;
}

// went away in python 3. who cares?
enum DATETIME_API_MAGIC = 0x414548d5;
__gshared PyDateTime_CAPI *PyDateTimeAPI;

PyDateTime_CAPI* PyDateTime_IMPORT()() {
    if (PyDateTimeAPI == null) {
        PyDateTimeAPI = cast(PyDateTime_CAPI *)
            PyCObject_Import(zc("datetime"), zc("datetime_CAPI"));
    }
    return PyDateTimeAPI;
}

// D translations of C macros:
int PyDate_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, PyDateTimeAPI.DateType);
}
int PyDate_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == PyDateTimeAPI.DateType;
}
int PyDateTime_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, PyDateTimeAPI.DateTimeType);
}
int PyDateTime_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == PyDateTimeAPI.DateTimeType;
}
int PyTime_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, PyDateTimeAPI.TimeType);
}
int PyTime_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == PyDateTimeAPI.TimeType;
}
int PyDelta_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, PyDateTimeAPI.DeltaType);
}
int PyDelta_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == PyDateTimeAPI.DeltaType;
}
int PyTZInfo_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, PyDateTimeAPI.TZInfoType);
}
int PyTZInfo_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == PyDateTimeAPI.TZInfoType;
}

PyObject* PyDate_FromDate()(int year, int month, int day) {
    return PyDateTimeAPI.Date_FromDate(year, month, day, PyDateTimeAPI.DateType);
}
PyObject* PyDateTime_FromDateAndTime()(int year, int month, int day, int hour, int min, int sec, int usec) {
    return PyDateTimeAPI.DateTime_FromDateAndTime(year, month, day, hour,
            min, sec, usec, Py_None, PyDateTimeAPI.DateTimeType);
}
PyObject* PyTime_FromTime()(int hour, int minute, int second, int usecond) {
    return PyDateTimeAPI.Time_FromTime(hour, minute, second, usecond,
            Py_None, PyDateTimeAPI.TimeType);
}
PyObject* PyDelta_FromDSU()(int days, int seconds, int useconds) {
    return PyDateTimeAPI.Delta_FromDelta(days, seconds, useconds, 1,
            PyDateTimeAPI.DeltaType);
}
PyObject* PyDateTime_FromTimestamp()(PyObject* args) {
    return PyDateTimeAPI.DateTime_FromTimestamp(
            cast(PyObject*) (PyDateTimeAPI.DateTimeType), args, null);
}
PyObject* PyDate_FromTimestamp()(PyObject* args) {
    return PyDateTimeAPI.Date_FromTimestamp(
            cast(PyObject*) (PyDateTimeAPI.DateType), args);
}


