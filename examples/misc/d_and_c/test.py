import os.path, sys
import distutils.util
libDir = os.path.join('build', 'lib.%s-%s' % (
    distutils.util.get_platform(),
    '.'.join(str(v) for v in sys.version_info[:2])
))
import sys
sys.path.append(libDir)
print (os.path)
import x, y
print ('hi')
