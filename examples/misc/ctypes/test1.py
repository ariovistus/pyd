from ctypes import *
import ctypes.util;
import os, os.path
from common import *
import common
common.dll = dll = CDLL(os.path.abspath("libtest1.so"))
dll.test_pyd.restype = py_object
dll.pyd_reg_fun('long_to_python', LCONV(my_id))

z = dll.test_pyd(py_object(1))
assert z == 3

