import sys
old_stdout = sys.stdout
sys.stdout = file('iterate.txt', 'w')

template = """\
        } else static if (ARGS == %s) {
            foreach (%s; t) {
                temp = _make_pytuple(%s);
                if (temp is null) StackContext.throwYield(new DPyYield(null));
                StackContext.throwYield(new DPyYield(temp));
            }"""

def args(i):
    return ['a%s' % i for i in range(0, i)]

def pyargs(i):
    return ['_py(%s)' % p for p in args(i)]

for i in range(2, 11):
    print template % (i, ', '.join(args(i)), ', '.join(pyargs(i)))
print '        }'

sys.stdout = old_stdout
