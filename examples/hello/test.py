import os.path, sys
import distutils.util

# Append the directory in which the binaries were placed to Python's sys.path,
# then import the D DLL.
libDir = os.path.join('build', 'lib.%s-%s' % (
    distutils.util.get_platform(),
    '.'.join(str(v) for v in sys.version_info[:2])
))
sys.path.append(os.path.abspath(libDir))
print (sys.path)
use = "1" 
if use == "1":
    import hello
elif use == "2":
    import hello2
elif use == 'both':
    import hello
    import hello2


try:
    if use == '1':
        hello.hello()
    elif use == '2':
        hello2.hello()
    elif use == 'both':
        hello.hello()
        hello2.hello()
except Exception as e:
    print (e)
    print (e.__dict__)

