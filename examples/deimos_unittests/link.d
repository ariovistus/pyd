import std.conv;
import deimos.python.Python;

// Linker seems to be a primary cause of failure.
// So test that the dratted thing is working!

unittest {
    PyObject* p = cast(PyObject*) &PyType_Type;
    assert(p !is null);
    assert(p.ob_type !is null);
    assert(p.ob_type.tp_name !is null);
    assert(to!string(p.ob_type.tp_name) == "type");
}

void main() {}
