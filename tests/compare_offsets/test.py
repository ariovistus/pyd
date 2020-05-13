import os.path, sys
import distutils.util
libDir = os.path.join('build', 'lib.%s-%s' % (
    distutils.util.get_platform(),
    '.'.join(str(v) for v in sys.version_info[:2])
))
import sys
sys.path.append(libDir)
import doffsets, coffsets

dx = doffsets.offsets()
cx = coffsets.offsets();

def xonly(x, a, b):
    only = set(a.keys()) - set(b.keys())
    print ("only found in %s:" % (x,))
    for k in only:
       print (k)

if len(dx) > len(cx):
    xonly("D", dx, cx)
    sys.exit(1)
elif len(cx) > len(dx):
    xonly("C", cx, dx)
    sys.exit(1)

good_sum = 0
all_sum = len(dx)
for k in dx.keys():
    d_o = dx.get(k)
    c_o = cx.get(k)
    if d_o is None or c_o is None:
        print(k, d_o, c_o)
    if d_o != c_o:
        print ("%s  D=0x%x  C=0x%x" % (k, d_o, c_o))
    else:
        good_sum += 1

print ('compared %s offsets, %s were same' % (all_sum, good_sum))

if all_sum != good_sum: sys.exit(1)
