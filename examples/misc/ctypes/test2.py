from ctypes import *
import ctypes.util;
import os, os.path

from common import *
import common
common.dll = dll = CDLL(os.path.abspath("libtest2.so"))
dll.test_pyd.restype = py_object
dll.test_long_to_d.restype = py_object
reg_fun('long_to_python', LCONV(my_id))
reg_fun('ulong_to_python', LUCONV(my_id))
reg_fun('get_item', FUNC2(get_item))

z = dll.test_long_to_d(py_object(1))
assert z == 3
a = set()
z = dll.test_pyd(py_object([1,2,3,a,5,6]))
assert a is z

