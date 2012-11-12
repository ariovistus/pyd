from ctypes import *
import ctypes.util;
import os, os.path
dll = CDLL(os.path.abspath("libtest3.so"))
dll.test_pyd.restype = py_object
STRFUNC1 = CFUNCTYPE(py_object, c_char_p)
def _raise(buf):
    print '_raise.buf: ', type(buf)
    raise Exception(buf)
dll.pyd_reg_fun('raise', STRFUNC1(_raise))
print 'zip'

dll.test_pyd(py_object(1))

