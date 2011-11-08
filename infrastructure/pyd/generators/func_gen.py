f = open('func_gen.txt', 'w')

template = """\
        static if (ARGS > %s) {
            ArgType!(typeof(fn), %s) arg%s;
        }
"""

for i in range(10):
    f.write(template % (i, i+1, i+1))
