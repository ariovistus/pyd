import sys
import time
import os.path
import distutils.util

libDir = os.path.join('build', 'lib.%s-%s' % (
    distutils.util.get_platform(),
    '.'.join(str(v) for v in sys.version_info[:2])
))
sys.path.append(os.path.abspath(libDir))

import libmarsv5camera_py as lc
lc.find("192.168.0.10")
try:
    import thread
except ImportError:
    import _thread as thread

def acquire_and_get_image(loop_times):
        for i in range(loop_times):
                lc.acquire(5)
                lc.getImage()

th1 = thread.start_new_thread(acquire_and_get_image, (1,))
import threading
