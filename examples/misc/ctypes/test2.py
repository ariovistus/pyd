from ctypes import *
import ctypes.util;
import os, os.path

from common import reg_fun
import common
common.dll = dll = CDLL(os.path.abspath("libtest2.so"))
dll.test_pyd.restype = py_object
dll.test_long_to_d.restype = py_object
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
    
LCONV = CFUNCTYPE(py_object, c_longlong)
reg_fun('long_to_python', LCONV(_id))
LUCONV = CFUNCTYPE(py_object, c_ulonglong)
reg_fun('ulong_to_python', LUCONV(_id))
UTF8CONV = CFUNCTYPE(py_object, c_void_p, c_size_t)
reg_fun('utf8_to_python', UTF8CONV(utf8_to_str))
reg_fun('get_item', FUNC2(get_item))
print 'test2 zip'
print dll.test_long_to_d(py_object(1))

a = set()
#z = dll.test_pyd(py_object([1,2,3,a,5,6]))
#print a is z

