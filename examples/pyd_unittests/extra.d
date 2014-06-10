import pyd.pyd, pyd.embedded, pyd.extra;
import deimos.python.Python;
import std.complex;

static this() {
    py_init();
}

unittest {
    alias cfloat_ = Complex!float;
    
    cfloat_[] data = [
        cfloat_(1,2),
        cfloat_(1,3),
        cfloat_(1,4),
        cfloat_(1,6),
    ];

    auto npa = d_to_python_numpy_ndarray(data);
    auto npop = new PydObject(npa);
    assert(npop[0].imag.to_d!float() == 2);
    assert(npop[0].getattr("real").to_d!float() == 1);

    foreach(i, datum; data) {
        assert(npop[i].imag.to_d!float() == datum.im);
        assert(npop[i].getattr("real").to_d!float() == datum.re);
    }
}

unittest {
    alias cfloat_ = const(Complex!float);
    
    cfloat_[] data = [
        cfloat_(1,2),
        cfloat_(1,3),
        cfloat_(1,4),
        cfloat_(1,6),
    ];

    auto npa = d_to_python_numpy_ndarray(data);
    auto npop = new PydObject(npa);
    assert(npop[0].imag.to_d!float() == 2);
    assert(npop[0].getattr("real").to_d!float() == 1);

    foreach(i, datum; data) {
        assert(npop[i].imag.to_d!float() == datum.im);
        assert(npop[i].getattr("real").to_d!float() == datum.re);
    }
}

unittest {
    bool[] data = [true, false, true, true, false];
    auto npa = new PydObject(d_to_python_numpy_ndarray(data));
    foreach(i, datum; data) {
        assert(npa[i].to_d!bool() == datum);

    }
}

void main() {}
