import sys;
old_stdout = sys.stdout
sys.stdout = open("tuple.txt", 'w')

template = """tuple!(%s)
make_tuple(%s)(%s) {
    tuple!(%s) t;"""

for i in range(1, 11):
    t_args = []
    f_args = []
    for j in range(1, i+1):
        t_args.append("T%s" % j)
        f_args.append("T%s t%s" % (j, j))
    t_args = ', '.join(t_args)
    f_args = ', '.join(f_args)
    print template % (t_args, t_args, f_args, t_args)
    for j in range(1, i+1):
        print "    t.arg%s = t%s;" % (j, j)
    print "    return t;"
    print "}"
    print

sys.stdout = old_stdout
