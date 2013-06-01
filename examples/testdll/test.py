import os.path, sys
import distutils.util

# Append the directory in which the binaries were placed to Python's sys.path,
# then import the D DLL.
libDir = os.path.join('build', 'lib.%s-%s' % (
    distutils.util.get_platform(),
    '.'.join(str(v) for v in sys.version_info[:2])
  ))
sys.path.append(os.path.abspath(libDir))
import testdll

testdll.foo()

print

print testdll.bar(12)

print

print "testdll.baz():"
testdll.baz()
print "testdll.baz(20):"
testdll.baz(20)
print "testdll.baz(30, 'cat'):"
testdll.baz(30, 'cat')

print

print "Testing callback support"
def foo():
    print "Callback works!"
testdll.dg_test(foo)
print "Testing delegate wrapping"
dg = testdll.func_test()
dg()

print

print "Testing class wrapping"
a = testdll.Foo(10)
print "Class instantiated!"
print "Testing method wrapping:"
a.foo()
print "Testing property wrapping:"
print a.i
a.i = 50
print a.i
print "Testing operator overloading"
print a+a

print "Testing range iteration wrapping:"
for i in a:
    print i

print

print "Testing exception wrapping"
try:
    testdll.throws()
except RuntimeError, e:
    print "Success: Exception caught!"
    print e

print

S = testdll.S
s = S()
print "s.s = 'hello'"
s.s = 'hello'
print "s.s"
print s.s
print "s.write_s()"
s.write_s()

print

print "Testing custom conversion function"
print testdll.conv1()
testdll.conv2(20)

print

print '--------'
print 'SUCCESS'
print '--------'
