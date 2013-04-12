from ctypes import *
dll = None
LIST = []
def reg_fun(nom, fun):
    LIST.append(fun)
    dll.pyd_reg_fun(nom, fun)
UTF8CONV = CFUNCTYPE(py_object, POINTER(c_char), c_size_t)
def utf8_to_str(_buffer, _len):
    bz = bytearray(_len)
    for i in xrange(_len): bz[i] = _buffer[i];
    return unicode(str(bz), 'utf8' )
LCONV = CFUNCTYPE(py_object, c_longlong)
LUCONV = CFUNCTYPE(py_object, c_ulonglong)
def my_id(l): return l
FUNC2 = CFUNCTYPE(py_object, py_object, py_object)
def get_item(thing, index): return thing[index]
