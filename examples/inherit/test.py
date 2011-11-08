import os.path, sys
import distutils.util

# Append the directory in which the binaries were placed to Python's sys.path,
# then import the D DLL.
libDir = os.path.join('build', 'lib.%s-%s' % (
    distutils.util.get_platform(),
    '.'.join(str(v) for v in sys.version_info[:2])
))
sys.path.append(os.path.abspath(libDir))

import inherit

b = inherit.Base(1)
d = inherit.Derived(2)

b.foo()
b.bar()
d.foo()
d.bar()

print "issubclass(inherit.Derived, inherit.Base)"
print issubclass(inherit.Derived, inherit.Base)

inherit.call_poly(b)
inherit.call_poly(d)

#w = inherit.WrapDerive()
#inherit.call_poly(w)

class PyClass(inherit.Derived):
    def foo(self):
        print 'PyClass.foo'

p = PyClass(3)
#print "The basic inheritance support breaks down here:"
inherit.call_poly(p)

print

b1 = inherit.return_poly_base()
print "inherit.return_poly_base returned instance of Base"
b1.foo()
b1.bar()
#assert type(b1) == inherit.Base
b2 = inherit.return_poly_derived()
b2a = inherit.return_poly_derived()
print "inherit.return_poly_derived returned instance of Derived"
#assert type(b2) == inherit.Derived
print "inherit.return_poly_derived returned the same object twice"
assert b2 is b2a

print
print '-------'
print 'SUCCESS'
print '-------'
