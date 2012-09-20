
import pyd.pyd, pyd.embedded;
import std.range;
import std.conv;
import std.c.stdio;
import std.algorithm;
import std.exception;
import deimos.python.Python;
import std.stdio;

void main() {
    on_py_init({
            add_module!(ModuleName!"testing")();
    });
    py_init();
    py_stmts(
            "from numpy import eye\n"
            "a = eye(4,k=1)\n",
            "testing");
    PydObject ao = py_eval("a","testing");
    PyObject* a = Py_INCREF(ao.ptr);
    writefln("got result of eye(4), which is of type %s:", to!string(a.ob_type.tp_name));
    writeln(ao);
    if(PyObject_CheckBuffer(a)) {
        printf("a supports the new-style buffer interface!\n");
        printf("tp_as_buffer: %x\n", a.ob_type.tp_as_buffer);
        printf("bf_getbuffer: %x\n", &a.ob_type.tp_as_buffer.bf_getbuffer);

        Py_buffer buffer;
        if(PyObject_GetBuffer(a, &buffer, PyBUF_SIMPLE/*|PyBUF_ND|PyBUF_STRIDES*/|PyBUF_FORMAT) != -1) {
            printf("PyObject_GetBuffer succeeded\n");
            Py_ssize_t len = buffer.len;
            int readonly = buffer.readonly;
            int ndim = buffer.ndim;
            string format = to!string(buffer.format);
            Py_ssize_t[] shape = buffer.shape ? buffer.shape[0 .. ndim] : [];
            Py_ssize_t[] strides = buffer.strides ? buffer.strides[0 .. ndim] : [];
            Py_ssize_t[] suboffsets = buffer.suboffsets ? buffer.suboffsets[0 .. ndim] : [];
            Py_ssize_t itemsize = buffer.itemsize;
            writefln("len: %s", len);
            writefln("itemsize: %s", itemsize);
            writefln("readonly: %s", readonly);
            writefln("format: %s", format);
            writefln("ndim: %s", ndim);
            writefln("shape: %s", shape);
            writefln("strides: %s", strides);
            writefln("suboffsets: %s", suboffsets);

            ulong[] data = (cast(ulong*) buffer.buf)[0 .. len/ulong.sizeof];
            writefln("data: %s" ,data);
            ulong[4][4] rect_data = 
                [[0, 1, 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1],
                 [0, 0, 0, 0]];
            writefln("rata: %s" ,(cast(ulong*)rect_data.ptr)[0 .. 16]);

        }else{
            printf("PyObject_GetBuffer failed\n");
        }
    }

}
