/**
  mirror datetime.h
  */
module deimos.python.datetime;

version(Python_3_1_Or_Later) {
    version = PyCapsule;
}else version(Python_3_0_Or_Later) {
    version = PyCObject;
}else version(Python_2_7_Or_Later) {
    version = PyCapsule;
}else {
    version = PyCObject;
}

import deimos.python.object;
import deimos.python.pyport;
version(PyCapsule) {
    import deimos.python.pycapsule;
}else version(PyCObject) {
    import deimos.python.cobject;
}else static assert(0);


extern(C):
// Python-header-file: Include/datetime.h:

/** # of bytes for year, month, and day. */
enum _PyDateTime_DATE_DATASIZE = 4;
/** # of bytes for hour, minute, second, and usecond. */
enum _PyDateTime_TIME_DATASIZE = 6;
/** # of bytes for year, month, day, hour, minute, second, and usecond. */
enum _PyDateTime_DATETIME_DATASIZE = 10;

/// subclass of PyObject.
struct PyDateTime_Delta {
    mixin PyObject_HEAD;

    /** -1 when unknown */
    Py_hash_t hashcode;
    /** -MAX_DELTA_DAYS <= days <= MAX_DELTA_DAYS */
    int days;
    /** 0 <= seconds < 24*3600 is invariant */
    int seconds;
    /** 0 <= microseconds < 1000000 is invariant */
    int microseconds;
}
/** a pure abstract base clase */
struct PyDateTime_TZInfo {
    mixin PyObject_HEAD;
}

/** The datetime and time types have hashcodes, and an optional tzinfo member,
 * present if and only if hastzinfo is true.
 */
template _PyTZINFO_HEAD() {
    mixin PyObject_HEAD;
    /// _
    Py_hash_t hashcode;
    /// _
    ubyte hastzinfo;
}

/** No _PyDateTime_BaseTZInfo is allocated; it's just to have something
 * convenient to cast to, when getting at the hastzinfo member of objects
 * starting with _PyTZINFO_HEAD.
 */
struct _PyDateTime_BaseTZInfo {
    mixin _PyTZINFO_HEAD;
}

/** All time objects are of PyDateTime_TimeType, but that can be allocated
 * in two ways, with or without a tzinfo member.  Without is the same as
 * tzinfo == None, but consumes less memory.  _PyDateTime_BaseTime is an
 * internal struct used to allocate the right amount of space for the
 * "without" case.
 */
template _PyDateTime_TIMEHEAD() {
    mixin _PyTZINFO_HEAD;
    /// _
    ubyte[_PyDateTime_TIME_DATASIZE] data;
}

/// _
struct _PyDateTime_BaseTime {
    mixin _PyDateTime_TIMEHEAD;
}

/// _
struct PyDateTime_Time {
    mixin _PyDateTime_TIMEHEAD;
    version(Python_3_6_Or_Later) {
        ubyte fold;
    }
    PyObject* tzinfo;
}

/** All datetime objects are of PyDateTime_DateTimeType, but that can be
 * allocated in two ways too, just like for time objects above.  In addition,
 * the plain date type is a base class for datetime, so it must also have
 * a hastzinfo member (although it's unused there).
 */
struct PyDateTime_Date {
    mixin _PyTZINFO_HEAD;
    /// _
    ubyte[_PyDateTime_DATE_DATASIZE] data;
}

/// _
template _PyDateTime_DATETIMEHEAD() {
    mixin _PyTZINFO_HEAD;
    ubyte[_PyDateTime_DATETIME_DATASIZE] data;
}

/// _
struct _PyDateTime_BaseDateTime {
    mixin _PyDateTime_DATETIMEHEAD;
}

/// _
struct PyDateTime_DateTime {
    mixin _PyDateTime_DATETIMEHEAD;
    version(Python_3_6_Or_Later) {
        ubyte fold;
    }
    PyObject* tzinfo;
}

// D translations of C macros:
/** Applies for date and datetime instances. */
int PyDateTime_GET_YEAR()(PyObject* o) {
    PyDateTime_Date* ot = cast(PyDateTime_Date*) o;
    return (ot.data[0] << 8) | ot.data[1];
}
/** Applies for date and datetime instances. */
int PyDateTime_GET_MONTH()(PyObject* o) {
    PyDateTime_Date* ot = cast(PyDateTime_Date*) o;
    return ot.data[2];
}
/** Applies for date and datetime instances. */
int PyDateTime_GET_DAY()(PyObject* o) {
    PyDateTime_Date* ot = cast(PyDateTime_Date*) o;
    return ot.data[3];
}

/** Applies for date and datetime instances. */
int PyDateTime_DATE_GET_HOUR()(PyObject* o) {
    PyDateTime_DateTime* ot = cast(PyDateTime_DateTime*) o;
    return ot.data[4];
}
/** Applies for date and datetime instances. */
int PyDateTime_DATE_GET_MINUTE()(PyObject* o) {
    PyDateTime_DateTime* ot = cast(PyDateTime_DateTime*) o;
    return ot.data[5];
}
/** Applies for date and datetime instances. */
int PyDateTime_DATE_GET_SECOND()(PyObject* o) {
    PyDateTime_DateTime* ot = cast(PyDateTime_DateTime*) o;
    return ot.data[6];
}
/** Applies for date and datetime instances. */
int PyDateTime_DATE_GET_MICROSECOND()(PyObject* o) {
    PyDateTime_DateTime* ot = cast(PyDateTime_DateTime*) o;
    return (ot.data[7] << 16) | (ot.data[8] << 8) | ot.data[9];
}

version(Python_3_6_Or_Later) {
    /// _
    int PyDateTime_DATE_GET_FOLD()(PyObject* o) {
        auto ot = cast(PyDateTime_DateTime*)o;
        return ot.fold;
    }
}

/** Applies for time instances. */
int PyDateTime_TIME_GET_HOUR()(PyObject* o) {
    PyDateTime_Time* ot = cast(PyDateTime_Time*) o;
    return ot.data[0];
}
/** Applies for time instances. */
int PyDateTime_TIME_GET_MINUTE()(PyObject* o) {
    PyDateTime_Time* ot = cast(PyDateTime_Time*) o;
    return ot.data[1];
}
/** Applies for time instances. */
int PyDateTime_TIME_GET_SECOND()(PyObject* o) {
    PyDateTime_Time* ot = cast(PyDateTime_Time*) o;
    return ot.data[2];
}
/** Applies for time instances. */
int PyDateTime_TIME_GET_MICROSECOND()(PyObject* o) {
    PyDateTime_Time* ot = cast(PyDateTime_Time*) o;
    return (ot.data[3] << 16) | (ot.data[4] << 8) | ot.data[5];
}

version(Python_3_6_Or_Later) {
    /// _
    int PyDateTime_TIME_GET_FOLD()(PyObject* o) {
        auto ot = cast(PyDateTime_Time*) o;
        return ot.fold;
    }
}

/** Structure for C API. */
struct PyDateTime_CAPI {
    /** type objects */
    PyTypeObject* DateType;
    /// ditto
    PyTypeObject* DateTimeType;
    /// ditto
    PyTypeObject* TimeType;
    /// ditto
    PyTypeObject* DeltaType;
    /// ditto
    PyTypeObject* TZInfoType;

    version(Python_3_7_Or_Later) {
        PyObject* TimeZone_UTC;
    }

    /** constructors */
    PyObject* function(int, int, int, PyTypeObject*) Date_FromDate;
    /// ditto
    PyObject* function(int, int, int, int, int, int, int,
            PyObject*, PyTypeObject*)
        DateTime_FromDateAndTime;
    /// ditto
    PyObject* function(int, int, int, int, PyObject*, PyTypeObject*)
        Time_FromTime;
    /// ditto
    PyObject* function(int, int, int, int, PyTypeObject*) Delta_FromDelta;
    /// ditto
    version(Python_3_7_Or_Later) {
        PyObject* function(PyObject *offset, PyObject *name) TimeZone_FromTimeZone;
    }

    /** constructors for the DB API */
    PyObject* function(PyObject*, PyObject*, PyObject*) DateTime_FromTimestamp;
    /// ditto
    PyObject* function(PyObject*, PyObject*) Date_FromTimestamp;

    version(Python_3_6_Or_Later) {
        PyObject* function(int, int, int, int, int, int, int, PyObject*, int, PyTypeObject*)
            DateTime_FromDateAndTimeAndFold;

        PyObject* function(int, int, int, int, PyObject*, int, PyTypeObject*)
            Time_FromTimeAndFold;
    }
}

// went away in python 3. who cares?
enum DATETIME_API_MAGIC = 0x414548d5;

version(PyCapsule) {
    enum PyDateTime_CAPSULE_NAME = "datetime.datetime_CAPI";
}

/// _
static PyDateTime_CAPI* PyDateTimeAPI;
PyDateTime_CAPI* PyDateTime_IMPORT()() {
    if (PyDateTimeAPI == null) {
        version(PyCapsule) {
            PyDateTimeAPI = cast(PyDateTime_CAPI*)
                PyCapsule_Import(PyDateTime_CAPSULE_NAME, 0);
        }else {
            PyDateTimeAPI = cast(PyDateTime_CAPI*)
                PyCObject_Import("datetime", "datetime_CAPI");
        }
    }
    return PyDateTimeAPI;
}

// D translations of C macros:
version(Python_3_7_Or_Later) {
    /// _
    PyObject* PyDateTime_TimeZone_UTC()() {
        return PyDateTimeAPI.TimeZone_UTC;
    }
}
/// _
int PyDate_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, PyDateTimeAPI.DateType);
}
/// _
int PyDate_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == PyDateTimeAPI.DateType;
}
/// _
int PyDateTime_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, PyDateTimeAPI.DateTimeType);
}
/// _
int PyDateTime_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == PyDateTimeAPI.DateTimeType;
}
/// _
int PyTime_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, PyDateTimeAPI.TimeType);
}
/// _
int PyTime_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == PyDateTimeAPI.TimeType;
}
/// _
int PyDelta_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, PyDateTimeAPI.DeltaType);
}
/// _
int PyDelta_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == PyDateTimeAPI.DeltaType;
}
/// _
int PyTZInfo_Check()(PyObject* op) {
    return PyObject_TypeCheck(op, PyDateTimeAPI.TZInfoType);
}
/// _
int PyTZInfo_CheckExact()(PyObject* op) {
    return Py_TYPE(op) == PyDateTimeAPI.TZInfoType;
}

/// _
PyObject* PyDate_FromDate()(int year, int month, int day) {
    return PyDateTimeAPI.Date_FromDate(year, month, day, PyDateTimeAPI.DateType);
}
/// _
PyObject* PyDateTime_FromDateAndTime()(
        int year, int month, int day, int hour, int min, int sec, int usec) {
    return PyDateTimeAPI.DateTime_FromDateAndTime(
            year, month, day, hour, min, sec, usec,
            cast(PyObject*) Py_None(), PyDateTimeAPI.DateTimeType);
}

version(Python_3_6_Or_Later) {
    /// _
    PyObject* PyDateTime_FromDateAndTimeAndFold()(
            int year, int month, int day, int hour, int min, int sec,
            int usec, int fold) {
        return PyDateTimeAPI.DateTime_FromDateAndTimeAndFold(
                year, month, day, hour,
                min, sec, usec, cast(PyObject*) Py_None(), fold,
                PyDateTimeAPI.DateTimeType);
    }
}

/// _
PyObject* PyTime_FromTime()(int hour, int minute, int second, int usecond) {
    return PyDateTimeAPI.Time_FromTime(hour, minute, second, usecond,
            cast(PyObject*) Py_None(), PyDateTimeAPI.TimeType);
}

version(Python_3_6_Or_Later) {
    /// _
    PyObject* PyTime_FromTimeAndFold()(
            int hour, int minute, int second, int usecond, int fold) {
        return PyDateTimeAPI.Time_FromTimeAndFold(hour, minute, second, usecond,
                cast(PyObject*) Py_None(), fold, PyDateTimeAPI.TimeType);
    }
}
/// _
PyObject* PyDelta_FromDSU()(int days, int seconds, int useconds) {
    return PyDateTimeAPI.Delta_FromDelta(days, seconds, useconds, 1,
            PyDateTimeAPI.DeltaType);
}
version(Python_3_7_Or_Later) {
    /// _
    PyObject* PyTimeZone_FromOffset()(PyObject* offset) { 
        return PyDateTimeAPI.TimeZone_FromTimeZone(offset, null);
    }

    /// _
    PyObject* PyTimeZone_FromOffsetAndName()(PyObject* offset, PyObject* name) { 
        return PyDateTimeAPI.TimeZone_FromTimeZone(offset, name);
    }
}
/// _
PyObject* PyDateTime_FromTimestamp()(PyObject* args) {
    return PyDateTimeAPI.DateTime_FromTimestamp(
            cast(PyObject*) (PyDateTimeAPI.DateTimeType), args, null);
}
/// _
PyObject* PyDate_FromTimestamp()(PyObject* args) {
    return PyDateTimeAPI.Date_FromTimestamp(
            cast(PyObject*) (PyDateTimeAPI.DateType), args);
}
