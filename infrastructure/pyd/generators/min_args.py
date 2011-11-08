import sys
old_stdout = sys.stdout
sys.stdout = open('min_args.txt', 'w')

arg_template = """I!(%s)()"""

template = """\
\telse static if (is(typeof(fn(%s))))
\t\tconst uint minArgs = %s;"""

for i in range(21):
    args = []
    for j in range(i):
        args.append(arg_template % (j,))
    print template % (", ".join(args), i)

sys.stdout = old_stdout

