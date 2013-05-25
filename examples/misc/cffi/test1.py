from cffi import FFI
import ctypes.util;
import os, os.path

ffi = FFI()

ffi.cdef("""
        int int_test(int,int);
        """);
ffi.cdef("""
        double float_test(double,double);
        """);
ffi.cdef("""
        typedef struct {
            size_t length;
            char *ptr;
        } DString;
        DString str_test(DString,DString);
        """)
doh = ffi.dlopen(os.path.abspath("libtest1.so"))


print (doh.int_test(1,2));
print (doh.float_test(100,1));
def DString(str_):
    return {'length': len(str_), 'ptr':ffi.new("char[]",str_)}
s1 = ffi.new("DString *")
s1.ptr = ffi.new("char[]", "world peace")
s1.length = len("world peace")
s2 = ffi.new("DString *")
s2.ptr = ffi.new("char[]", "bricks")
s2.length = len("bricks")

mystr = (doh.str_test(DString("world peace"),DString("world peace")))
print mystr.length
print mystr.ptr
import pdb
pdb.set_trace()


