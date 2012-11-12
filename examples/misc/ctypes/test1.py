from ctypes import *
import ctypes.util;
import os, os.path
dll = CDLL(os.path.abspath("libtest1.so"))
dll.test_pyd.restype = py_object
def _type(obj): return type(obj)
def _id(l): 
    print '_id l: ', type(l)
    return l
FUNC2 = CFUNCTYPE(py_object, py_object, py_object)
def get_item(thing, index):
    print 'get_item thing: ', type(thing)
    print 'get_item index: ', type(index)
    return thing[index]
def utf8_to_str(_buffer, _len):
    a = create_string_buffer(_buffer, _len)
    return a.value
#dll.init_pyd(LCONV(c_longlong), LUCONV(c_ulonglong), FUNC2(get_item))
#dll.init_pyd(LCONV(_id), LUCONV(_id), FUNC2(get_item))
LCONV = CFUNCTYPE(py_object, c_longlong)
dll.pyd_reg_fun('long_to_python', LCONV(_id))
print 'zip'

z = dll.test_pyd(py_object(1))
print z

