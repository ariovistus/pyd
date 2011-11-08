import sys
old_stdout = sys.stdout
sys.stdout = open('callable_wrap.txt', 'w')

template = """\
    Tr fn(Tr, %s)(%s) {
        return boilerplate!(Tr)(call(%s));
    }
"""

for i in range(1, 11):
    t_args = []
    f_args = []
    c_args = []
    for j in range(1, i+1):
        t_args.append("T%s" % j)
        f_args.append("T%s t%s" % (j, j))
        c_args.append("t%s" % j)
    print template % (", ".join(t_args), ", ".join(f_args), ", ".join(c_args))

sys.stdout = old_stdout
