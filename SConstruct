from os.path import join
import re, sys
rx = re.compile("(\d+)\.(\d+)")

def pv_split(pyversion):
    m = rx.match(pyversion)
    maj = int(m.group(1));
    min = int(m.group(2));
    assert maj in [2,3], "invalid python version: %s" % pyversion
    if maj == 2: assert min in range(4,8), "invalid python version: %s" % pyversion
    if maj == 3: assert False, "python 3000 not supported"
    if maj == 3: assert min in range(0,3), "invalid python version: %s" % pyversion
    return maj,min

def py_versions(pyversion):
    maj, min = pv_split(pyversion)
    return ["Python_%s_%s_Or_Later" % (maj, min_) for min_ in range(4, min+1)]

def py_lib(pyversion):
    return ["-L-lpython"+pyversion]

infra = "#infrastructure"
pydfiles =  (Glob(join(infra,"meta","*.d"))   +
            Glob(join(infra,"util","*.d"))    +
            Glob(join(infra,"pyd","*.d"))     +
            [join(infra,"python","python.d")])

env27 = Environment(
    DPATH = [infra, join(infra, "python")],
    DVERSIONS = py_versions("2.7"),
    DFLAGS = ['-unittest', '-property', '-debug', '-gc'],
    DLINKFLAGS = py_lib("2.7"),
    )
if sys.platform.lower().startswith("win"): exe_suffix = ".exe"
else: exe_suffix = ".x"
Export('infra', 'py_versions', 'py_lib', 'pydfiles', 'join', 'env27', "exe_suffix")
SConscript([
    join("examples","pyind","SConscript"),
    join("examples", "pyd_unittests","SConscript"),
    join("infrastructure", "SConscript"),
    ])

