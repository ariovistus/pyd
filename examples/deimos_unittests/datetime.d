import deimos.python.Python;

shared static this() {
    Py_Initialize();
    PyDateTime_IMPORT();
}

unittest {
    PyObject* date = PyDateTime_FromDateAndTime(2010,7,4,12,31,30,1);

    assert(PyDateTime_GET_YEAR(date) == 2010);
    assert(PyDateTime_GET_MONTH(date) == 7);
    assert(PyDateTime_GET_DAY(date) == 4);
    assert(PyDateTime_DATE_GET_HOUR(date) == 12);
    assert(PyDateTime_DATE_GET_MINUTE(date) == 31);
    assert(PyDateTime_DATE_GET_SECOND(date) == 30);
    assert(PyDateTime_DATE_GET_MICROSECOND(date) == 1);
}

void main () {}
