f = open('fn_to_dg.txt', 'w')

template = """\
    } else static if (ARGS == %s) {
        alias RetType delegate(%s) type;
"""

inner_template = """ArgType!(Fn, %s)"""

for i in range(1, 11):
    inner_parts = []
    for j in range(1, i+1):
        inner_parts.append(inner_template % j)
    f.write(template % (i, ', '.join(inner_parts)))
f.write("    }")
