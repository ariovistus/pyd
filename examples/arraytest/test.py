import os.path, sys
import distutils.util

# Append the directory in which the binaries were placed to Python's sys.path,
# then import the D DLL.
libDir = os.path.join('build', 'lib.%s-%s' % (
    distutils.util.get_platform(),
    '.'.join(str(v) for v in sys.version_info[:2])
))
sys.path.append(os.path.abspath(libDir))
from arraytest import Foo, get, set, test

#set([Foo(1), Foo(2), Foo(3)])
print ">>> get()"
print `get()`
print ">>> set([Foo(10), Foo(20)])"
#set(a=[Foo(10), Foo(20)])
set([Foo(10), Foo(20)])
print ">>> get()"
print `get()`

