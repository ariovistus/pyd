import os.path, sys
import distutils.util

# Append the directory in which the binaries were placed to Python's sys.path,
# then import the D DLL.
libDir = os.path.join('build', 'lib.%s-%s' % (
    distutils.util.get_platform(),
    '.'.join(str(v) for v in sys.version_info[:2])
))
sys.path.append(os.path.abspath(libDir))
import rawexample

rawexample.hello()

b = rawexample.Base()
d = rawexample.Derived()

b.foo()
b.bar()
d.foo()
d.bar()

