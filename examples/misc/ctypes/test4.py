from ctypes import *
import ctypes.util;
import os, os.path
from common import *
import common
common.dll = dll = CDLL(os.path.abspath("libtest4.so"))
dll.test_pyd.restype = py_object

reg_fun('utf8_to_python', UTF8CONV(utf8_to_str))

a = dll.test_pyd(1)
assert a == u'Doctor!\0'
a = dll.test_pyd(2)
assert a == u'Doctor!\0 Doctor!\0'
a = dll.test_pyd(5)
assert a == u'Doctor!\0 Doctor!\0 \u3061!\0 Doctor!\0 Doctor!\0'

